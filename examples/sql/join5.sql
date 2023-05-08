SELECT Supplier.SupplierNumber,
  Part.PartNumber,
  SupplierPart.Quantity
FROM './examples/data/S.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN './examples/data/SP.csv' AS SupplierPart (SupplierNumber, PartNumber, Quantity) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber
  JOIN './examples/data/P.csv' AS Part (
    PartNumber,
    PartName,
    Color,
    Weight,
    City
  ) ON SupplierPart.PartNumber = Part.PartNumber
  JOIN './examples/data/S.csv' AS SS (
    SupplierNumber,
    SupplierName,
    Status,
    City
  ) ON SS.City = Part.City;