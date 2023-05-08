-- Check must functions 
SELECT
  Supplier.SupplierNumber,
  Supplier.SupplierName,
  TOUPPER(Supplier.City),
  (34 || 'peller') AS MIXED
FROM
  './examples/data/S.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  );

SELECT
  *
FROM
  S AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
  JOIN SP AS SupplierPart (SupplierNumber, PartNumber, Quantity) ON Supplier.SupplierNumber = SupplierPart.SupplierNumber;

SELECT
  B.*,
  A.NISSE AS Putte,
  MAX(Sultan) AS MAX_SULTAN
FROM
  S AS sss(k);

SELECT
  GENAD.*
FROM
VALUES
  ('43619', '56', '49'),
  ('45', '46', '51') AS GENAD (COLA, COLB, COLC)
WHERE
  GENAD.COLB - '11' != 80 / 2 + 5;

SELECT
  B.*,
  A.NISSE AS Putte,
  MAX(Sultan) AS MAX_SULTAN
FROM
  S AS sss(k);

SELECT
  *
FROM
  S AS sss(k);

SELECT
  (
    SELECT
      *
    FROM
      SP AS SP(D)
  ) AS NAMNET
FROM
  S AS sss(k);

SELECT
  A,
  B AS BBB,
  T.*,
  MAX(OOO)
FROM
  S AS sss(k);

SELECT
  *
FROM
  S AS sss(k);