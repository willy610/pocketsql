SELECT
  Supplier.City,
  AVG(Supplier.Status),
  MIN(Supplier.Status),
  MAX(Supplier.Status),
  SUM(Supplier.Status),
  STDDEV(Supplier.Status) AS STDEV
FROM
  './examples/data/s.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
GROUP BY
  Supplier.City;