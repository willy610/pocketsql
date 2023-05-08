SELECT
  files.name,
  files.extension,
  files.size,
  COUNT(files.dir) AS COUNT_FILES
FROM
  './examples/data/usersixten.csv' AS files(
    dir,
    name,
    extension,
    type,
    date,
    time,
    size
  )
WHERE
  files.type = 'F'
GROUP BY
  files.name,
  files.extension,
  files.size
HAVING
  COUNT(files.dir) > 1
ORDER BY
  3 DESC;