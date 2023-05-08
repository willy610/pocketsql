SELECT files.dir,
  COUNT(files.name) AS COUNT_NAME_GT_100,
  SUM(files.size) AS SUM_SIZE
FROM './examples/data/usersixten.csv' AS files(
    dir,
    name,
    extension,
    type,
    date,
    time,
    size
  )
GROUP BY files.dir
HAVING COUNT(files.name) > 50
ORDER BY SUM_SIZE;