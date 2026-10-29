namespace asset.mgmt;

using { cuid, managed, sap.common.CodeList } from '@sap/cds/common';

type AssignmentStatus : String(20) enum { Requested; Assigned; Rejected; Cancelled; ReturnRequested; Returned; }

entity Categories : CodeList {
  key code : String(20);
}

entity Statuses : CodeList {
  key code : AssignmentStatus;
}

entity Products : cuid, managed {
  name              : String(100) @mandatory;
  category          : Association to Categories @assert.target;
  description       : String(500);
  imageUrl          : String(500);
  totalQuantity     : Integer default 0;
  availableQuantity : Integer default 0;
  assignments       : Association to many Assignments on assignments.product = $self;
}

entity Employees : cuid, managed {
  firstName   : String(50)  @mandatory;
  lastName    : String(50)  @mandatory;
  email       : String(100) @mandatory;
  department  : String(50);
  fullName    : String = firstName || ' ' || lastName;
  assignments : Association to many Assignments on assignments.employee = $self;
}

entity Assignments : cuid, managed {
  product        : Association to Products @mandatory;
  employee       : Association to Employees;
  status         : AssignmentStatus default 'Requested';
  assignedAt     : Date;
  dueDate        : Date;
  returnedAt     : Date;
  comment        : String(500);   // request reason / note
  managerComment : String(500);   // manager decision, e.g. rejection reason
}