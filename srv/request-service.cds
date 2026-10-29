using { asset.mgmt as db } from '../db/schema';

service RequestService @(requires: 'Viewer') {

  @readonly
  entity Products as projection on db.Products {
    ID, name, category, description, imageUrl
  };

  @readonly
  entity Categories as projection on db.Categories;

  @readonly
  entity Statuses as projection on db.Statuses;

  @readonly
  @restrict: [{ grant: 'READ', where: 'email = $user' }]
  entity Employees as projection on db.Employees {
    ID, firstName, lastName, fullName, email, department
  };

  @odata.draft.enabled
  @restrict: [
    { grant: ['READ', 'UPDATE', 'DELETE', 'cancelRequest', 'requestReturn'], to: 'Viewer', where: 'employee.email = $user' },
    { grant: 'CREATE',                     to: 'Viewer' }
  ]
  entity MyRequests as projection on db.Assignments {
    *,
    virtual null as statusCriticality : Integer
  }
    actions {
      action cancelRequest() returns MyRequests;
      action requestReturn() returns MyRequests;
    };
}