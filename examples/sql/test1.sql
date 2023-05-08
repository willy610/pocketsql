SELECT
    GENAD.COLA,
    GENAD.COLC,
    GENAD.COLB,
    (23 || '->' || GENAD.COLB)
FROM
VALUES
    ('43619', '56', '49'),
    ('20045', '20046', '2051') AS GENAD (COLA, COLB, COLC)
WHERE
    ((GENAD.COLB + 3) = (45 + 14))
    AND GENAD.COLC != '123';