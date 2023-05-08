SELECT
  Supplier.SupplierNumber,
  MAX(SupplierPart.Quantity)
FROM
  './examples/data/S.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN './examples/data/SP.csv' AS SupplierPart (SupplierNumber, PartNumber, Quantity) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber
GROUP BY
  Supplier.SupplierNumber;