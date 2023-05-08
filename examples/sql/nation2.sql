SELECT 
  countries.name, 
  countries.area 
FROM 
  './examples/data/countries.csv' AS countries (
    country_id, name, area, national_day, 
    country_code2, country_code3, region_id
  ) 
WHERE 
  countries.country_id IN (
    SELECT 
      countries.country_id 
    FROM 
      countries
    WHERE 
      countries.area > 5000000
  ) 
ORDER BY 
  area, 
  name;
