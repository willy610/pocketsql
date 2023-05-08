SELECT
  Supplier.SupplierNumber,
  Part.PartNumber,
  SupplierPart.Quantity
FROM
VALUES
  ('S1', "Smith", 20, 'London'),
  ('S2', "Jones", 10, 'Paris'),
  ('S3', "Blake", 30, 'Paris'),
  ('S4', "Clark", 20, 'London'),
  ('S5', 'Adams', 20, 'Athens') AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN
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
  ('P2', 'Bolt', 'Green', 17, 'Paris'),
  ('P3', 'Screw', 'Blue', 17, 'Rome'),
  ('P4', 'Screw', 'Red', 14, 'London'),
  ('P5', 'Cam', 'Blue', 12, 'Paris'),
  ('P6', 'Cog', 'Red', 19, 'London') AS Part (
    PartNumber,
    PartName,
    Color,
    Weight,
    City
  ) ON SupplierPart.PartNumber >= Part.PartNumber;