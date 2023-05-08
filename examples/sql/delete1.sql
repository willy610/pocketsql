DELETE 
FROM
  './examples/data/s.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  WHERE Supplier.Status = '20' ;