SELECT
  Supplier.City,
  MAX(Supplier.Status) AS MAX_STATUS,
  AVG(Supplier.Status) AS AVG_STATUS
FROM
  './examples/data/s.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
GROUP BY
  Supplier.City;