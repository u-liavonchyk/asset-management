using {asset.mgmt as db} from '../db/schema';

service AnalyticsService @(requires: 'Analytics') {

    @readonly
    entity Categories as
        projection on db.Categories {
            key code,
                name,
                descr
        };

    @readonly
    entity Statuses as
        projection on db.Statuses {
            key code,
                name,
                descr
        };

    @readonly
    entity Products as
        projection on db.Products {
            key ID,
                name,
                category.code as category_code,
                description,
                totalQuantity,
                availableQuantity,
                totalQuantity - availableQuantity as assignedQuantity : Integer
        };

    @readonly
    entity Employees as
        projection on db.Employees {
            key ID,
                firstName,
                lastName,
                fullName,
                email,
                department
        };

    @readonly
    entity Assignments as
        projection on db.Assignments {
            key ID,
                product.ID  as product_ID,
                employee.ID as employee_ID,
                status,
                requestDate,
                assignedAt,
                dueDate,
                returnedAt,
                1 as requestCount : Integer
        };
}
