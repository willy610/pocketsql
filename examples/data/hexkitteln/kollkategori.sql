SELECT
    DISTINCT *
FROM
    './examples/data/hexkitteln/kategori.csv' AS kategori(Kategori,Kategoribeskrivning)
    
    ORDER BY Kategori;