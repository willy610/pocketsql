SELECT
  Supplier.SupplierNumber,
  Part.PartName
FROM
VALUES
  ('S1', "Smith", 20, 'London'),
  ('S2', "Jonson", 10, 'Paris'),
  ('S4', "Clark", 20, 'London'),
  ('S5', 'Adams', 20, 'Athens') AS Supplier (SupplierNumber, SupplierName, Status, City)
  LEFT JOIN
VALUES
  ('S1', 'P1', 300),
  ('S1', 'P2', 200),
  ('S1', 'P3', 400),
  ('S1', 'P4', 200),
  ('S1', 'P5', 100),
  ('S1', 'P6', 100),
  ('S2', 'P1', 300),
  ('S2', 'P2', 400),
  ('S3', 'P2', 200),
  ('S4', 'P2', 200),
  ('S4', 'P4', 300),
  ('S4', 'P5', 400) AS SupplierPart (SupplierNumber, PartNumber, Quantity) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber
  JOIN
VALUES
  ('P1', 'Nut', 'Red', 12, 'London'),
  ('P2', 'Bolt', 'Green', 17, 'Paris') AS Part (PartNumber, PartName, Color, Weight, City) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber
WHERE
  Part.PartName != 'Bolt';