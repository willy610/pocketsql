
SELECT kategorirecept.Kategori, COUNT(kategorirecept.Recept) AS COUNTING
FROM
    './examples/data/hexkitteln/kategorirecept.csv' AS kategorirecept(Kategori,Recept)
GROUP BY kategorirecept.Kategori

ORDER BY COUNTING DESC
;




SELECT
    DISTINCT kategorirecept.Kategori
FROM
    './examples/data/hexkitteln/kategorirecept.csv' AS kategorirecept(Kategori,Recept)
    
    ;

