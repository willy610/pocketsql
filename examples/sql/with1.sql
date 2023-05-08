WITH  MINIS (COLA, COLB) AS ( SELECT 
    S.SNO, 
    S.SNAME 
  FROM 
    './examples/data/s.csv' AS S (SNO, SNAME, STATUS, CITY)
) 
SELECT 
  MINIS.COLA 
FROM 
  MINIS AS MINIS (COLA, COLB);
