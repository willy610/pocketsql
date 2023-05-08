SELECT 
  * 
FROM 
  './examples/data/regions.csv' AS regions(region_id, name, continent_id) 
  JOIN './examples/data/continents.csv' AS continents(continent_id, name) ON regions.continent_id = continents.continent_id;
