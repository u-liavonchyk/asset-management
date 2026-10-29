using AssetService as service from '../../srv/services';

annotate service.Assignments with @(
  UI.HeaderInfo      : {
    TypeName       : 'Assignment',
    TypeNamePlural : 'Assignments',
    Title          : { Value: product.name },
    Description    : { Value: employee.fullName }
  },

  UI.SelectionFields : [ product_ID, employee_ID, status, dueDate ],

  UI.LineItem        : [
    { Value: product_ID,  Label: 'Product' },
    { Value: employee_ID, Label: 'Employee' },
    { Value: status,      Label: 'Status', Criticality: statusCriticality, CriticalityRepresentation: #WithIcon },
    { Value: assignedAt,  Label: 'Assigned On' },
    { Value: dueDate,     Label: 'Due Date' },
    { Value: returnedAt,  Label: 'Returned On' },
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.approve',       Label: 'Approve' },
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.reject',        Label: 'Reject' },
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.confirmReturn', Label: 'Confirm Return' }
  ],

  UI.Identification  : [
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.approve',       Label: 'Approve' },
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.reject',        Label: 'Reject' },
    { $Type: 'UI.DataFieldForAction', Action: 'AssetService.confirmReturn', Label: 'Confirm Return' }
  ],

  UI.FieldGroup #General : {
    Data : [
      { Value: product_ID,     Label: 'Product' },
      { Value: employee_ID,    Label: 'Employee' },
      { Value: status,         Label: 'Status', Criticality: statusCriticality, CriticalityRepresentation: #WithIcon },
      { Value: assignedAt,     Label: 'Assigned On' },
      { Value: dueDate,        Label: 'Due Date' },
      { Value: returnedAt,     Label: 'Returned On' },
      { Value: comment,        Label: 'Comment' },
      { Value: managerComment, Label: 'Manager Comment' }
    ]
  },

  UI.Facets : [
    { $Type: 'UI.ReferenceFacet', ID: 'General', Label: 'General Information', Target: '@UI.FieldGroup#General' }
  ],

  UI.UpdateHidden : true,
  UI.DeleteHidden : true
);

annotate service.Assignments with {
  product    @(Common: {
    Label           : 'Product',
    Text            : product.name,
    TextArrangement : #TextOnly,
    ValueList       : {
      CollectionPath : 'Products',
      Parameters     : [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: product_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'category_code' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'availableQuantity' }
      ]
    }
  });
  employee   @(Common: {
    Label           : 'Employee',
    Text            : employee.fullName,
    TextArrangement : #TextOnly,
    ValueList       : {
      CollectionPath : 'Employees',
      Parameters     : [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: employee_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'fullName' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'department' }
      ]
    }
  });
  status         @(Common: {
    Label                    : 'Status',
    ValueListWithFixedValues : true,
    ValueList                : {
      CollectionPath : 'Statuses',
      Parameters     : [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: status, ValueListProperty: 'code' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
      ]
    }
  }) @readonly;
  returnedAt     @Common.Label: 'Returned On'     @readonly;
  assignedAt     @Common.Label: 'Assigned On';
  dueDate        @Common.Label: 'Due Date';
  comment        @Common.Label: 'Comment'         @UI.MultiLineText;
  managerComment @Common.Label: 'Manager Comment' @readonly @UI.MultiLineText;
};

annotate service.Statuses with {
  code @Common.Label: 'Status' @Common.Text: name @Common.TextArrangement: #TextOnly;
  name @Common.Label: 'Status';
};

annotate service.Assignments with actions {
  approve @(
    Common.SideEffects      : { TargetProperties: [ 'in/*' ], TargetEntities: [ 'in/product' ] },
    Core.OperationAvailable : { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Requested' ] } }
  );

  @(
    Common.SideEffects      : { TargetProperties: [ 'in/*' ] },
    Core.OperationAvailable : { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Requested' ] } }
  )
  reject(reason @Common.Label: 'Rejection Reason' @UI.MultiLineText);

  confirmReturn @(
    Common.SideEffects      : { TargetProperties: [ 'in/*' ], TargetEntities: [ 'in/product' ] },
    Core.OperationAvailable : { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'ReturnRequested' ] } }
  );
};
