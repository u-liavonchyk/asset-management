import cds from '@sap/cds';

const { SELECT, UPDATE } = cds.ql;

const ACTIVE  = ['Requested', 'Assigned', 'ReturnRequested'];
const HOLDING = ['Assigned', 'ReturnRequested'];            

export default class AssetService extends cds.ApplicationService {
  init() {
    const { Products, Employees, Assignments } = this.entities;
    const { Products: DbProducts, Assignments: DbAssignments } = cds.entities('asset.mgmt');

    const today = () => new Date().toISOString().slice(0, 10);
    const keyOf = req => {
      const p = req.params?.at?.(-1);
      return req.data?.ID ?? (typeof p === 'object' ? p?.ID : p);
    };
    const load = req => SELECT.one.from(DbAssignments).where({ ID: keyOf(req) });
    const count = async where =>
      (await SELECT.one.from(DbAssignments).columns('count(*) as n').where(where))?.n ?? 0;
    // atomic transition: applies only if the status is still the expected one
    const transition = (ID, from, data) => UPDATE(DbAssignments).set(data).where({ ID, status: from });

    // ================= Products =================
    this.before('CREATE', Products, req => {
      const d = req.data;
      if (!(d.totalQuantity >= 0)) return req.error(400, 'Total quantity must be 0 or greater', 'totalQuantity');
      d.availableQuantity = d.totalQuantity;
    });

    this.before('UPDATE', Products, async req => {
      const d = req.data;
      if (d.totalQuantity == null) return;
      if (d.totalQuantity < 0) return req.error(400, 'Total quantity must be 0 or greater', 'totalQuantity');
      const holding = await count({ product_ID: keyOf(req), status: { in: HOLDING } });
      if (d.totalQuantity < holding)
        return req.error(400, `Total quantity cannot be less than ${holding}: that many items are currently assigned`, 'totalQuantity');
      d.availableQuantity = d.totalQuantity - holding;
    });

    this.before('DELETE', Products, async req => {
      const n = await count({ product_ID: keyOf(req), status: { in: ACTIVE } });
      if (n) return req.error(409, `Product cannot be deleted: it has ${n} open request(s) or assignment(s)`);
    });

    this.before('DELETE', Employees, async req => {
      const n = await count({ employee_ID: keyOf(req), status: { in: ACTIVE } });
      if (n) return req.error(409, `Employee cannot be deleted: they have ${n} open request(s) or assignment(s)`);
    });

    // ================= Assignments =================
    this.before('CREATE', Assignments, async req => {
      const d = req.data;
      if (!d.product_ID)  return req.error(400, 'Select a product', 'product_ID');
      if (!d.employee_ID) return req.error(400, 'Select an employee', 'employee_ID');

      Object.assign(d, { status: 'Assigned', returnedAt: null, managerComment: null });
      d.assignedAt ??= today();
      if (d.dueDate && d.dueDate < d.assignedAt)
        return req.error(400, 'Due date cannot be before the assignment date', 'dueDate');

      const stock = await UPDATE(DbProducts, d.product_ID)
        .with({ availableQuantity: { '-=': 1 } })
        .where({ availableQuantity: { '>': 0 } });
      if (!stock) return req.error(409, 'This product is out of stock', 'product_ID');
    });

    this.before(['EDIT', 'UPDATE', 'DELETE'], Assignments, req =>
      req.error(405, 'Assignments cannot be edited or deleted. Use Approve, Reject or Confirm Return'));

    this.on('approve', Assignments, async req => {
      const a = await load(req);
      if (!a) return req.reject(404, 'Request not found');
      if (a.status !== 'Requested') return req.reject(409, `Only requested items can be approved (current status: ${a.status})`);
      if (a.dueDate && a.dueDate < today())
        return req.reject(409, 'The requested due date has already passed. Reject the request so the employee can submit a new one');

      if (!await transition(a.ID, 'Requested', { status: 'Assigned', assignedAt: today() }))
        return req.reject(409, 'This request has already been processed');

      const stock = await UPDATE(DbProducts, a.product_ID)
        .with({ availableQuantity: { '-=': 1 } })
        .where({ availableQuantity: { '>': 0 } });
      if (!stock) return req.reject(409, 'Product is out of stock, the request cannot be approved');

      return this.run(SELECT.one.from(req.subject));
    });

    this.on('reject', Assignments, async req => {
      const a = await load(req);
      if (!a) return req.reject(404, 'Request not found');
      if (a.status !== 'Requested') return req.reject(409, `Only requested items can be rejected (current status: ${a.status})`);
      const reason = req.data.reason?.trim();
      if (!reason) return req.reject(400, 'Please provide a rejection reason', 'reason');

      if (!await transition(a.ID, 'Requested', { status: 'Rejected', managerComment: reason }))
        return req.reject(409, 'This request has already been processed');
      return this.run(SELECT.one.from(req.subject));
    });

    this.on('confirmReturn', Assignments, async req => {
      const a = await load(req);
      if (!a) return req.reject(404, 'Assignment not found');
      if (a.status !== 'ReturnRequested')
        return req.reject(409, `Return can be confirmed only after the employee requested it (current status: ${a.status})`);

      if (!await transition(a.ID, 'ReturnRequested', { status: 'Returned', returnedAt: today() }))
        return req.reject(409, 'This return has already been processed');
      await UPDATE(DbProducts, a.product_ID).with({ availableQuantity: { '+=': 1 } });

      return this.run(SELECT.one.from(req.subject));
    });

    const CRITICALITY = { Requested: 2, ReturnRequested: 2, Assigned: 3, Rejected: 1, Cancelled: 0, Returned: 0 };
    this.after('READ', Assignments, rows => {
      for (const r of [].concat(rows ?? [])) if (r?.status) r.statusCriticality = CRITICALITY[r.status] ?? 0;
    });

    return super.init();
  }
}