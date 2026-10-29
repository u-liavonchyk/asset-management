import cds from '@sap/cds';

const { SELECT, UPDATE } = cds.ql;

export default class RequestService extends cds.ApplicationService {
  init() {
    const { MyRequests } = this.entities;
    const { Products: DbProducts, Employees: DbEmployees, Assignments: DbAssignments } = cds.entities('asset.mgmt');

    const today = () => new Date().toISOString().slice(0, 10);
    const keyOf = req => {
      const p = req.params?.at?.(-1);
      return req.data?.ID ?? (typeof p === 'object' ? p?.ID : p);
    };
    const load = req => SELECT.one.from(DbAssignments).where({ ID: keyOf(req) });
    const transition = (ID, from, data) => UPDATE(DbAssignments).set(data).where({ ID, status: from });
    // fields the employee is not allowed to set
    const PROTECTED = ['employee_ID', 'status', 'assignedAt', 'returnedAt', 'managerComment'];

    this.before('CREATE', MyRequests, async req => {
      const d = req.data;
      const me = await SELECT.one.from(DbEmployees).columns('ID').where({ email: req.user.id });
      if (!me) return req.error(403, `User ${req.user.id} is not registered as an employee`);

      if (!d.product_ID) return req.error(400, 'Select a product', 'product_ID');
      const product = await SELECT.one.from(DbProducts).columns('ID').where({ ID: d.product_ID });
      if (!product) return req.error(400, 'Product not found', 'product_ID');
      if (d.dueDate && d.dueDate < today()) return req.error(400, 'Due date cannot be in the past', 'dueDate');

      for (const f of PROTECTED) delete d[f];
      Object.assign(d, { employee_ID: me.ID, status: 'Requested' });
    });

    this.before(['EDIT', 'UPDATE'], MyRequests, async req => {
      const a = await load(req);
      if (a && a.status !== 'Requested')
        return req.error(409, `Only pending requests can be changed (current status: ${a.status})`);
      if (req.event === 'UPDATE') {
        for (const f of PROTECTED) delete req.data[f];
        if (req.data.dueDate && req.data.dueDate < today())
          return req.error(400, 'Due date cannot be in the past', 'dueDate');
      }
    });

    this.before('DELETE', MyRequests, req =>
      req.error(405, 'Requests cannot be deleted. Use Cancel Request instead'));

    this.on('cancelRequest', MyRequests, async req => {
      const a = await load(req);
      if (!a) return req.reject(404, 'Request not found');
      if (a.status !== 'Requested') return req.reject(409, `Only pending requests can be cancelled (current status: ${a.status})`);
      if (!await transition(a.ID, 'Requested', { status: 'Cancelled' }))
        return req.reject(409, 'This request has already been processed');
      return this.run(SELECT.one.from(req.subject));
    });

    this.on('requestReturn', MyRequests, async req => {
      const a = await load(req);
      if (!a) return req.reject(404, 'Assignment not found');
      if (a.status !== 'Assigned') return req.reject(409, `Only assigned products can be returned (current status: ${a.status})`);
      if (!await transition(a.ID, 'Assigned', { status: 'ReturnRequested' }))
        return req.reject(409, 'This assignment has already been processed');
      return this.run(SELECT.one.from(req.subject));
    });

    const CRITICALITY = { Requested: 2, ReturnRequested: 2, Assigned: 3, Rejected: 1, Cancelled: 0, Returned: 0 };
    this.after('READ', MyRequests, rows => {
      for (const r of [].concat(rows ?? [])) if (r?.status) r.statusCriticality = CRITICALITY[r.status] ?? 0;
    });

    return super.init();
  }
}