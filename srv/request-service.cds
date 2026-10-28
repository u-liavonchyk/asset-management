using { asset.mgmt as db } from '../db/schema';

service RequestService @(requires: 'Viewer') {

  @readonly
  entity Products as projection on db.Products {
    ID, name, category, description
  };

  @readonly
  @restrict: [{ grant: 'READ', where: 'email = $user' }]
  entity Employees as projection on db.Employees {
    ID, firstName, lastName, fullName, email, department
  };

  @readonly
  entity Categories as projection on db.Categories;

  @odata.draft.enabled
  @restrict: [
    { grant: ['READ', 'UPDATE', 'DELETE', 'cancelRequest', 'requestReturn'], to: 'Viewer', where: 'employee.email = $user' },
    { grant: 'CREATE', to: 'Viewer' }
  ]
  entity MyRequests as projection on db.Assignments
    actions {
      action cancelRequest() returns MyRequests;
      action requestReturn() returns MyRequests;
    };
}