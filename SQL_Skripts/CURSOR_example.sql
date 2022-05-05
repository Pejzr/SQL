DECLARE @name VARCHAR(50) -- database name 
DECLARE @cmd VARCHAR(100)

DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM MASTER.dbo.sysdatabases 
WHERE name like '%mzdy%'

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	  set @cmd = 'ALTER DATABASE ' + @name + ' SET AUTO_SHRINK OFF;'
	  exec (@cmd)

      FETCH NEXT FROM db_cursor INTO @name 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 