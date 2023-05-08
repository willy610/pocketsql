SELECT
    GENAD.COLA,
    GENAD.COLC,
    GENAD.COLB
FROM
VALUES
    (43619, 56, 49),
    (45, 46, 51) AS GENAD (COLA, COLB, COLC)
WHERE
    GENAD.COLC = (
        (45 + 1) + 3 + (
            SELECT
                KKK.AAA
            FROM
            VALUES
                (0) AS KKK (AAA)
        )
    );