SELECT 
    countries.name, 
    countries.area,
    countries.country_id
FROM 
    './examples/data/countries.csv' 
    
    AS countries (country_id,name,area,national_day,country_code2,country_code3,region_id)
WHERE countries.country_id IN VALUES (12,15,31,38,42,182,224)
;

ORDER BY
    area, 
    name;