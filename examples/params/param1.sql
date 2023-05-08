SELECT
  Supplier.City
FROM
  './examples/data/s.csv' AS Supplier (
    SupplierNumber,
    SupplierName,
    Status,
    City
  )
WHERE
  Supplier.Status > ?typ20
GROUP BY
  Supplier.City;