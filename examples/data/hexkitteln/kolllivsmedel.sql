SELECT
    DISTINCT *
FROM
    './examples/data/hexkitteln/livsmedel.csv' AS livsmedel(livsmedel, kcal, notering, pris	)
    
    ORDER BY pris;