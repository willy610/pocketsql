-- Find livsmedel in receptstegsingrediens which has no key in  has no livsmedel
WITH NONERECURSIVE Livsmedelkeys  (Livsmedel) AS (     SELECT 
 Receptstegsingrediens.Livsmedel  FROM './examples/data/hexkitteln/receptstegsingrediens.csv' AS 
 Receptstegsingrediens (Recept,Steg,Livsmedel,Antal,Enhet) 
)
SELECT DISTINCT Livsmedelkeys.Livsmedel 
FROM Livsmedelkeys AS Livsmedelkeys (Livsmedel)

WHERE Livsmedelkeys.Livsmedel NOT IN 
(SELECT DISTINCT Livsmedel.Livsmedel FROM './examples/data/hexkitteln/livsmedel.csv' 
AS Livsmedel(Livsmedel,kcal,notering,Pris))
;

+-------------------+
| Livsmedel         |
+-------------------+
| vin|vitt|torrt    |
|  rödlök           |
| fänkål|stött      |
| ris|långkornigt   |
| svartpeppar|malen |
| peppar|spansk     |
| ginger|ale        |
| äpplen|syrliga    |
| ärtor|socker      |
+-------------------+