SELECT
  *
FROM
  './examples/data/six10sites.csv' AS files(
    dir,
    name,
    extension,
    type,
    date,
    time,
    size
  )
WHERE
  files.name LIKE '_copy%'
  OR files.name LIKE 'Untitled_'
ORDER BY
  dir,
  name,
  date,
  time,
  size;