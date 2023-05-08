SELECT
    *
FROM
    './examples/data/regions.csv' AS regions(region_id, name, continent_id)
WHERE
    regions.name LIKE '%Africa'
    AND regions.region_id > 12;