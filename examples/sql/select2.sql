
-- kooooo
SELECT
    SP.SNO,
    (
        SELECT
            P.PNO
        FROM
            './examples/data/P.csv' AS P(PNO, PNAME, COLOR, WEIGHT, CITY)
        WHERE
            P.PNO = SP.PNO
    ) AS P_PNO
FROM
    './examples/data/SP.csv' AS SP(SNO, PNO, QTY);