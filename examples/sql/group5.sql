SELECT
  recsteging.Enhet,
  MAX(recsteging.Antal),
  COUNT(recsteging.Antal)
FROM
  './examples/data/receptstegsingrediens.csv' AS recsteging (ReceptID, Steg, LivsmedelID, Antal, Enhet)
GROUP BY
  recsteging.Enhet
  
HAVING
  COUNT(recsteging.Antal) > 4
ORDER BY
  Enhet
  
  ;  
