WITH RECURSIVE possible_route (city_to, route, distance) AS (
  SELECT
    cities_route.city_to,
    (
      cities_route.city_from || '->' || cities_route.city_to
    ) AS route,
    cities_route.distance
  FROM
    './examples/data/citiesroute.csv' AS cities_route (city_from, city_to, distance)
  WHERE
    cities_route.city_from = 'Groningen'
  UNION
  ALL
  SELECT
    cities_route.city_to,
    (
      possible_route.route || '->' || cities_route.city_to
    ) AS route,
    (possible_route.distance + cities_route.distance) AS distance
  FROM
    possible_route AS possible_route (city_to, route, distance)
    INNER JOIN  cities_route  ON cities_route.city_from = possible_route.city_to
)
SELECT
  possible_route.route,
  possible_route.distance
FROM
  possible_route AS possible_route (city_to, route, distance)
WHERE
  possible_route.city_to = 'Haarlem';