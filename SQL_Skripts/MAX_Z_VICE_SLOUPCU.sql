SELECT [Other Fields],
  (SELECT Max(v) 
   FROM (VALUES (date1), (date2), (date3),...) AS value(v)) as [MaxDate]
FROM [YourTableName]