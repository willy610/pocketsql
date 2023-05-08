SELECT
  Supplier.SupplierNumber,
  SupplierPart.PartNumber
FROM
  './examples/data/S.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN './examples/data/SP.csv' AS SupplierPart (SupplierNumber, PartNumber, Quantity) 
  ON Supplier.SupplierNumber = SupplierPart.SupplierNumber;