SELECT
  recsteging.ReceptID,
  recsteging.Enhet
FROM
  './examples/data/receptstegsingrediens.csv' AS recsteging (ReceptID, Steg, LivsmedelID, Antal, Enhet)
GROUP BY
  recsteging.Enhet,
  recsteging.ReceptID;