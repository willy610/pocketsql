SELECT
  COUNT(recsteging.Antal)
FROM
  './examples/data/receptstegsingrediens.csv' AS recsteging (ReceptID, Steg, LivsmedelID, Antal, Enhet);