-- Find recepstep which has no recept
WITH NONERECURSIVE Receptkeys  (Recept) AS (     SELECT 
 Receptsteg.Recept  FROM './examples/data/hexkitteln/receptsteg.csv' AS
  Receptsteg (Recept,Steg,Kortbeskrivning,Minuter,Beskrivning) 
)
SELECT Receptkeys.Recept 
FROM Receptkeys AS Receptkeys (recept)

WHERE Receptkeys.Recept NOT IN 
(SELECT DISTINCT Recept.Recept FROM './examples/data/hexkitteln/recept.csv' 
AS Recept(Recept,AntalPortioner,TillagningsTid,Ursprung,Beskrivning,Skapad))
;

