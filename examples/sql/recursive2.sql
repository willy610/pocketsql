WITH RECURSIVE Ancestor (Parent) AS (
  SELECT ParentOf.Parent
  FROM './examples/data/ParentOf.csv' AS ParentOf(Parent, Child, BirthYear)
  WHERE ParentOf.Child = 'Frank'
  UNION ALL
  SELECT ParentOf.Parent
  FROM Ancestor AS Ancestor(Parent)
    JOIN ParentOf ON Ancestor.Parent = ParentOf.Child
)
SELECT Ancestor.Parent
FROM Ancestor AS Ancestor(Parent);