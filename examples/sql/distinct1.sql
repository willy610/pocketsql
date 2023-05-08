SELECT
    DISTINCT Receptstegsingrediens.Enhet
FROM
    './examples/data/Receptstegsingrediens.csv' AS Receptstegsingrediens(Recept, Steg, Livsmedel, Antal, Enhet);