WITH  MINIS (COLA, COLB) AS (
  SELECT
    S.SNO,
    S.SNAME
  FROM
    './examples/data/s.csv' AS S (SNO, SNAME, STATUS, CITY)
),
 XXX (COLA, COLB) AS (
  SELECT
    P.PNO,
    P.CITY
  FROM
    './examples/data/p.csv' AS P (PNO, PNAME, PCOLOR, STATUS, CITY)
)
SELECT
  XXX.COLA,
  XXX.COLB
FROM
  XXX AS XXX (COLA, COLB);