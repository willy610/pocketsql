SELECT
    S.SNO,
    S.SNAME
FROM
VALUES
    ('S1', 'Smith', 20, 'London'),
    ('S2', 'Jones', 10, 'Paris'),
    ('S3', 'Blake', 30, 'Paris'),
    ('S4', 'Clark', 20, 'London'),
    ('S5', 'Adams', 20, 'Athens') AS S (SNO, SNAME, STATUS, CITY)
WHERE
    'P2' IN (
        SELECT
            SP.PNO
        FROM
            './examples/data/SP.csv' AS SP (SNO, PNO, QTY)
        WHERE
            SP.SNO = S.SNO
    );