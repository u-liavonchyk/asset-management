using RequestService as service from '../../srv/request-service';

annotate service.MyRequests with @(
  UI.HeaderInfo      : {
    TypeName       : 'Request',
    TypeNamePlural : 'My Requests',
    Title          : { Value: product.name },
    Description    : { Value: status }
  },

  UI.SelectionFields : [ product_ID, status ],

  UI.LineItem        : [
    { Value: product_ID,     Label: 'Product' },
    { Value: status,         Label: 'Status' },
    { Value: dueDate,        Label: 'Needed Until' },
    { Value: assignedAt,     Label: 'Assigned On' },
    { Value: returnedAt,     Label: 'Returned On' },
    { Value: managerComment, Label: 'Manager Comment' },
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.cancelRequest', Label: 'Cancel Request' },
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.requestReturn', Label: 'Request Return' }
  ],

  UI.Identification  : [
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.cancelRequest', Label: 'Cancel Request' },
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.requestReturn', Label: 'Request Return' }
  ],

  UI.FieldGroup #Request : {
    Data : [
      { Value: product_ID, Label: 'Product' },
      { Value: dueDate,    Label: 'Needed Until' },
      { Value: comment,    Label: 'Reason' }
    ]
  },

  UI.FieldGroup #Decision : {
    Data : [
      { Value: status,         Label: 'Status' },
      { Value: assignedAt,     Label: 'Assigned On' },
      { Value: returnedAt,     Label: 'Returned On' },
      { Value: managerComment, Label: 'Manager Comment' }
    ]
  },

  UI.Facets : [
    { $Type: 'UI.ReferenceFacet', ID: 'Request',  Label: 'My Request', Target: '@UI.FieldGroup#Request' },
    { $Type: 'UI.ReferenceFacet', ID: 'Decision', Label: 'Status',     Target: '@UI.FieldGroup#Decision' }
  ],

  // no delete; edit only while the request is pending
  UI.DeleteHidden : true,
  UI.UpdateHidden : { $edmJson: { $Ne: [ { $Path: 'status' }, 'Requested' ] } }
);

annotate service.MyRequests with {
  product        @(Common: {
    Label           : 'Product',
    Text            : product.name,
    TextArrangement : #TextOnly,
    ValueList       : {
      CollectionPath : 'Products',
      Parameters     : [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: product_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'category_code' }
      ]
    }
  });
  employee       @UI.Hidden @readonly;
  status         @Common.Label: 'Status'          @readonly;
  assignedAt     @Common.Label: 'Assigned On'     @readonly;
  returnedAt     @Common.Label: 'Returned On'     @readonly;
  managerComment @Common.Label: 'Manager Comment' @readonly @UI.MultiLineText;
  dueDate        @Common.Label: 'Needed Until';
  comment        @Common.Label: 'Reason'          @UI.MultiLineText;
};

annotate service.MyRequests with actions {
  cancelRequest @(
    Common.SideEffects      : { TargetProperties: [ 'in/*' ] },
    Core.OperationAvailable : { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Requested' ] } }
  );
  requestReturn @(
    Common.SideEffects      : { TargetProperties: [ 'in/*' ] },
    Core.OperationAvailable : { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Assigned' ] } }
  );
};

annotate service.Products with {
  ID       @UI.Hidden;
  name     @Common.Label: 'Product';
  category @Common.Label: 'Category' @Common.Text: category.name @Common.TextArrangement: #TextOnly;
};

annotate service.Categories with {
  code @Common.Label: 'Code' @Common.Text: name @Common.TextArrangement: #TextOnly;
  name @Common.Label: 'Category';
};