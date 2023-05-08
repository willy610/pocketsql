SELECT
  files.name,
  COUNT(files.name)
FROM
  './examples/data/matte.csv' AS files(
    dir,
    name,
    extension,
    type,
    date,
    time,
    size
  )
GROUP BY
  files.name
HAVING
  COUNT(files.name) > 2
ORDER BY
  2;