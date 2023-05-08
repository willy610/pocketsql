SELECT
  files.name,
  files.extension,
  files.size,
  COUNT(files.dir) AS COUNT_FILES
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

WHERE
  files.type = 'F'


GROUP BY
  files.name,
  files.extension,
  files.size



ORDER BY
  4 DESC;