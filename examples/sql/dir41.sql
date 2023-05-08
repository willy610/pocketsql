-- kommentar
SELECT
    *
FROM
    './examples/data/SKETCHUP.csv' AS files(dir, name, extension, type, date, time, size)
WHERE
    files.dir = '/Users/sixten/SKETCHUP/MOA/AsosKitchen'
    AND files.type = 'F'
ORDER BY
    name;