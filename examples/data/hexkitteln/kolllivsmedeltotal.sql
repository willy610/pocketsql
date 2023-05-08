-- Find livsmedel in 
-- 
WITH NONERECURSIVE Receptkeys  (Recept) AS (     SELECT 
 Recept.Recept  FROM './examples/data/hexkitteln/recept.csv' AS 
 Recept (Recept,AntalPortioner,TillagningsTid,Ursprung,Beskrivning,Skapad) 
)
SELECT Receptkeys.Recept 
FROM Receptkeys AS Receptkeys (recept)

WHERE Receptkeys.Recept NOT IN 
(SELECT DISTINCT Receptsteg.Recept FROM './examples/data/hexkitteln/receptsteg.csv' 
AS Receptsteg(Recept,Steg,Kortbeskrivning,Minuter,Beskrivning))
;

