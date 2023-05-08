SELECT
  *
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
  files.name LIKE '_copy%'
  OR files.name LIKE 'Untitled%'
ORDER BY
  name,
  date,
  time,
  size;