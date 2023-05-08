SELECT 
  S.*,SP.*
  FROM './examples/data/S.csv' AS S (
    SNO,
    SNAME,
    STATUS,
    CITY
  ) 

  JOIN './examples/data/SP.csv' AS SP (SNO, PNO, QTY)
  ON S.SNO = SP.SNO 
  JOIN './examples/data/P.csv' AS P (
    PNO,
    PNAME,
    COLOR,
    Weight,
    CITY
  )
  ON SP.PNO = P.PNO 
  JOIN './examples/data/S.csv' AS SS (
    SNO,
    SNAME,
    STATUS,
    CITY)
    ON SS.CITY = P.CITY ;