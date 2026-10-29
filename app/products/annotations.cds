using AssetService as service from '../../srv/services';

annotate service.Products with @(
  UI.HeaderInfo      : {
    TypeName       : 'Product',
    TypeNamePlural : 'Products',
    Title          : { Value: name },
    Description    : { Value: category.name },
    ImageUrl       : imageUrl
  },

  UI.SelectionFields : [ name, category_code ],

  UI.LineItem        : [
    { Value: imageUrl,          Label: ' ' },
    { Value: name,              Label: 'Product' },
    { Value: category_code,     Label: 'Category' },
    { Value: totalQuantity,     Label: 'Total' },
    { Value: availableQuantity, Label: 'Available' },
    { Value: description,       Label: 'Description' }
  ],

  UI.FieldGroup #General : {
    Data : [
      { Value: name,          Label: 'Product' },
      { Value: category_code, Label: 'Category' },
      { Value: description,   Label: 'Description' },
      { Value: imageUrl,      Label: 'Image' }
    ]
  },

  UI.FieldGroup #Stock : {
    Data : [
      { Value: totalQuantity,     Label: 'Total Quantity' },
      { Value: availableQuantity, Label: 'Available' }
    ]
  },

  UI.Facets : [
    { $Type: 'UI.ReferenceFacet', ID: 'General',     Label: 'General Information',    Target: '@UI.FieldGroup#General' },
    { $Type: 'UI.ReferenceFacet', ID: 'Stock',       Label: 'Stock',                  Target: '@UI.FieldGroup#Stock' },
    { $Type: 'UI.ReferenceFacet', ID: 'Assignments', Label: 'Requests & Assignments', Target: 'assignments/@UI.LineItem#ProductAssignments' }
  ]
);

annotate service.Products with {
  name              @Common.Label: 'Product';
  category          @(Common: {
    Label                    : 'Category',
    Text                     : category.name,
    TextArrangement          : #TextOnly,
    ValueListWithFixedValues : true,
    ValueList                : {
      CollectionPath : 'Categories',
      Parameters     : [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: category_code, ValueListProperty: 'code' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
      ]
    }
  });
  description       @Common.Label: 'Description'    @UI.MultiLineText;
  imageUrl          @Common.Label: 'Image'          @UI.IsImageURL;
  totalQuantity     @Common.Label: 'Total Quantity';
  availableQuantity @Common.Label: 'Available';
};

annotate service.Categories with {
  code @Common.Label: 'Code' @Common.Text: name @Common.TextArrangement: #TextOnly;
  name @Common.Label: 'Category';
};

annotate service.Assignments with @(
  UI.LineItem #ProductAssignments : [
    { Value: employee_ID, Label: 'Employee' },
    { Value: status,      Label: 'Status', Criticality: statusCriticality, CriticalityRepresentation: #WithIcon },
    { Value: assignedAt,  Label: 'Assigned On' },
    { Value: dueDate,     Label: 'Due Date' },
    { Value: returnedAt,  Label: 'Returned On' }
  ]
);