WITH  Supplier (
  SupplierNumber, SupplierName, Status, 
  City
) AS (SELECT 
    S.SNO, 
    S.SNAME, 
    S.STATUS, 
    S.CITY 
  FROM 
    './examples/data/s.csv' AS S(SNO, SNAME, STATUS, CITY)
) 
SELECT 
  Supplier.SupplierNumber 
FROM 
  Supplier AS R(S);
