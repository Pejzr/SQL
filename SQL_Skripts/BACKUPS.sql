----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																																						--
--																DATABASE BACKUPS																		--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--	1. CREATE BACKUP OF SELECTED DBS
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @name VARCHAR(50) -- database name  
	DECLARE @path VARCHAR(256) -- path for backup files  
	DECLARE @fileName VARCHAR(256) -- filename for backup  
	DECLARE @fileDate VARCHAR(20) -- used for file name
 
	-- specify database backup directory
	SET @path = 'C:\Backup\'  
 
	-- convert date to string for later filename
	SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 
 
	DECLARE db_cursor CURSOR READ_ONLY FOR  
	SELECT name 
	FROM master.sys.databases 
	WHERE name NOT IN ('master','model','msdb','tempdb')	-- except these databases (here system dbs)
	AND state = 0	-- database is online
	AND is_in_standby = 0	-- database is not read only for log shipping
 
	OPEN db_cursor   
	FETCH NEXT FROM db_cursor INTO @name   
 
	WHILE @@FETCH_STATUS = 0   
	BEGIN   
	   SET @fileName = @path + @name + '_' + @fileDate + '.BAK'  -- set filename format
	   BACKUP DATABASE @name TO DISK = @fileName	-- create bacukup
 
	   FETCH NEXT FROM db_cursor INTO @name   
	END   
 
	CLOSE db_cursor   
	DEALLOCATE db_cursor

	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--	2. RESTORE BACKUP WITH OTHER NAME
----------------------------------------------------------------------------------------------------------------------------------------------------------

-- find truly name of .mdf and .ldf filenames
	RESTORE FILELISTONLY FROM DISK='c:\backup\your.bak'


-- based on previous, we add origin filename (.mdf and .ldf) to path
-- also can rename DB to what we want to see as by change string after MOVE clause (etc.: MOVE 'Skolici' -> MOVE 'Inuvio001')
	RESTORE DATABASE SH01  
	   FROM DISK = 'C:\DBS\VZ.bak'
	   WITH
	   MOVE 'Skolici' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.mdf', -- path, where we want store mdf file
	   MOVE 'Skolici_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.ldf';  -- path, where we want store log file
 
