WITH CITIESROUTE (city_from, city_to, distance) AS (
  SELECT FromValues.city_from,
    FromValues.city_to,
    FromValues.distance
  FROM
  VALUES ('Groningen', 'Heerenveen', '61.4'),
    ('Groningen', 'Harlingen', '91.6'),
    ('Harlingen', 'Wieringerwerf', '52.3'),
    ('Wieringerwerf', 'Hoorn', '26.5'),
    ('Hoorn', 'Amsterdam', '46.1'),
    ('Amsterdam', 'Haarlem', '30'),
    ('Heerenveen', 'Lelystad', '74'),
    ('Lelystad', 'Amsterdam', '57.2') AS FromValues (city_from, city_to, distance)
) RECURSIVE possible_route (city_to, route, distance) AS (
  SELECT CITIESROUTE.city_to,
    (
      CITIESROUTE.city_from || '->' || CITIESROUTE.city_to
    ) AS route,
    CITIESROUTE.distance
  FROM CITIESROUTE
  WHERE CITIESROUTE.city_from = 'Groningen'
  UNION ALL
  SELECT CITIESROUTE.city_to,
    (
      possible_route.route || '->' || CITIESROUTE.city_to
    ) AS route,
    (possible_route.distance + CITIESROUTE.distance) AS distance
  FROM possible_route AS possible_route (city_to, route, distance)
    INNER JOIN CITIESROUTE AS CITIESROUTE (city_from, city_to, distance) ON CITIESROUTE.city_from = possible_route.city_to
)
SELECT possible_route.route,
  possible_route.distance,
  possible_route.city_to
FROM possible_route AS possible_route (city_to, route, distance)
WHERE possible_route.city_to = 'Haarlem';