using { asset.mgmt as db } from '../db/schema';

service AssetService @(requires: 'Admin') {

  @odata.draft.enabled
  entity Products    as projection on db.Products;

  entity Employees   as projection on db.Employees;

  @readonly
  entity Categories  as projection on db.Categories;

  @readonly
  entity Statuses    as projection on db.Statuses;

  @odata.draft.enabled
  entity Assignments as projection on db.Assignments {
    *,
    virtual null as statusCriticality : Integer
  }
    actions {
      action approve()               returns Assignments;
      action reject(reason : String) returns Assignments;
      action confirmReturn()         returns Assignments;
    };
}

annotate AssetService.Products with {
  availableQuantity @readonly;   // calculated by the server only
};