SELECT
    Supplier.SupplierNumber
FROM
    './examples/data/S.csv' AS Supplier (SupplierNumber, SupplierName, Status, City);
