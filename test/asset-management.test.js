import cds from '@sap/cds';
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

const { GET, POST } = cds.test(import.meta.dirname + '/..');

const admin    = { auth: { username: 'admin', password: '' } };
const viewer   = { auth: { username: 'alice', password: '' } };
const employee = { auth: { username: 'uladzislau.liavonchyk@sap.com', password: '' } };

const REQUEST_ID  = '33333333-3333-4333-8333-000000000006'; // Logitech MX Keys, status Requested
const PRODUCT_ID  = '11111111-1111-4111-8111-000000000005'; // Logitech MX Keys, 6 available
const EMPLOYEE_ID = '22222222-2222-4222-8222-000000000005'; // Uladzislau Liavonchyk

const action = name =>
  `/odata/v4/asset/Assignments(ID=${REQUEST_ID},IsActiveEntity=true)/AssetService.${name}`;

// returns the HTTP status for both successful and failed requests
const statusOf = async promise => {
  try { return (await promise).status; }
  catch (e) { return e.response?.status ?? e.status ?? Number(String(e.message).match(/\b[45]\d\d\b/)?.[0]); }
};

describe('Authorization', () => {
  it('admin can read the product catalog', async () => {
    const { status, data } = await GET('/odata/v4/asset/Products?$filter=IsActiveEntity eq true', admin);
    assert.equal(status, 200);
    assert.equal(data.value.length, 5);
  });

  it('viewer is rejected from the admin service', async () => {
    assert.equal(await statusOf(GET('/odata/v4/asset/Products', viewer)), 403);
  });

  it('employee sees only own requests', async () => {
    const { data } = await GET('/odata/v4/request/MyRequests?$filter=IsActiveEntity eq true', employee);
    assert.ok(data.value.length > 0);
    assert.ok(data.value.every(r => r.employee_ID === EMPLOYEE_ID));
  });
});

describe('Request approval flow', () => {
  it('reject requires a reason', async () => {
    assert.equal(await statusOf(POST(action('reject'), {}, admin)), 400);
  });

  it('approve assigns the product and reduces the stock', async () => {
    const { status, data } = await POST(action('approve'), {}, admin);
    assert.equal(status, 200);
    assert.equal(data.status, 'Assigned');

    const { data: product } = await GET(`/odata/v4/asset/Products(ID=${PRODUCT_ID},IsActiveEntity=true)`, admin);
    assert.equal(product.availableQuantity, 5);
  });

  it('an already processed request cannot be approved again', async () => {
    assert.equal(await statusOf(POST(action('approve'), {}, admin)), 409);
  });

  it('return cannot be confirmed before the employee requests it', async () => {
    assert.equal(await statusOf(POST(action('confirmReturn'), {}, admin)), 409);
  });
});
