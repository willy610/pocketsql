SELECT
    DISTINCT Receptstegsingrediens.Enhet,
    Receptstegsingrediens.Antal
FROM
    './examples/data/Receptstegsingrediens.csv' AS Receptstegsingrediens(Recept, Steg, Livsmedel, Antal, Enhet)
WHERE
    Receptstegsingrediens.Antal > 1;

ORDER BY
    2 ASC,
    Enhet DESC;