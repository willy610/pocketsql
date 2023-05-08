WITH RECURSIVE company_hierarchy (
  ID,
  first_name,
  last_name,
  boss_id,
  hierarchy_level
) AS (
  SELECT employees.ID,
    employees.first_name,
    employees.last_name,
    employees.boss_id,
    0 AS hierarchy_level
  FROM './examples/data/employees.csv' AS employees(ID, first_name, last_name, boss_id)
  WHERE employees.boss_id = 0
  UNION ALL
  SELECT employees.ID,
    employees.first_name,
    employees.last_name,
    employees.boss_id,
    (
      company_hierarchy.hierarchy_level + 1
    ) AS hierarchy_level
  FROM employees
    JOIN company_hierarchy AS company_hierarchy(
      ID,
      first_name,
      last_name,
      boss_id,
      hierarchy_level
    ) ON employees.boss_id = company_hierarchy.ID
)
SELECT company_hierarchy.first_name,
  company_hierarchy.last_name,
  employees.first_name,
  employees.last_name,
  company_hierarchy.hierarchy_level
FROM company_hierarchy AS company_hierarchy(
    ID,
    first_name,
    last_name,
    boss_id,
    hierarchy_level
  )
  LEFT JOIN employees ON company_hierarchy.boss_id = employees.ID;
ORDER BY company_hierarchy.hierarchy_level,
  company_hierarchy.boss_id;