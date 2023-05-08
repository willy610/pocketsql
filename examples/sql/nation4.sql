WITH XXX (YYY) AS (
    SELECT countries.country_id
    FROM './examples/data/countries.csv' AS countries (
            country_id,
            name,
            area,
            national_day,
            country_code2,
            country_code3,
            region_id
        )
    WHERE countries.area > 5000000
)
SELECT countries.name,
    countries.area
FROM countries
WHERE countries.country_id IN (
        SELECT XXX.YYY
        FROM XXX AS XXX(YYY)
    );
ORDER BY area,
    name;