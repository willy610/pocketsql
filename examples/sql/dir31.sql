SELECT
  DISTINCT files.dir
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
  files.name LIKE '_ableclas_';