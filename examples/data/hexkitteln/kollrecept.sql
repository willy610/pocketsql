SELECT
    DISTINCT recept.Beskrivning
FROM
    './examples/data/hexkitteln/recept.csv' AS recept(Recept,AntalPortioner,TillagningsTid,Ursprung,Beskrivning,Skapad)
    
    ;


