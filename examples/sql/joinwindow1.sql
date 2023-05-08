SELECT
  Supplier.SupplierNumber,
  AVG(SupplierPart.Quantity) OVER (XXX)
FROM
  './examples/data/S.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN './examples/data/SP.csv' AS SupplierPart (SupplierNumber, PartNumber, Quantity) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber 
  
  WINDOW XXX AS (PARTITION BY Supplier.SupplierNumber);