----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--													ANALYZA A OPTIMALIZACE INDEXU, STATISTIK															--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


	USE XXX		--<< DOPLN DATABAZI


----------------------------------------------------------------------------------------------------------------------------------------------------------
--			ULOZENI PUVODNICH EXTERNICH INDEXU DO TABULKY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('TmpxExterniIndexy') IS NULL
		CREATE TABLE TmpxExterniIndexy (name NVARCHAR(128) PRIMARY KEY, DatumZapisu DATETIME DEFAULT GETDATE())
	INSERT INTO TmpxExterniIndexy (name)
	SELECT name FROM SYS.indexes WHERE NAME LIKE 'IXe%' AND NAME NOT IN (SELECT name FROM TmpxExterniIndexy)




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			VYPIS VSECH INDEXU NA TABULCE
----------------------------------------------------------------------------------------------------------------------------------------------------------

	EXEC SP_HELPINDEX 		--<< DOPLN TABULKU




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			STAV FRAGMENTACE INDEXU
----------------------------------------------------------------------------------------------------------------------------------------------------------	

	SELECT S.NAME AS 'Schema',
		   T.NAME AS 'Table',
		   I.NAME AS 'Index',
		   DDIPS.avg_fragmentation_in_percent,
		   DDIPS.page_count
	FROM   sys.Dm_db_index_physical_stats (Db_id(), NULL, NULL, NULL, NULL) AS DDIPS
		   INNER JOIN sys.tables T
				   ON T.object_id = DDIPS.object_id
		   INNER JOIN sys.schemas S
				   ON T.schema_id = S.schema_id
		   INNER JOIN sys.indexes I
				   ON I.object_id = DDIPS.object_id
					  AND DDIPS.index_id = I.index_id
	WHERE  DDIPS.database_id = Db_id()
		   AND I.NAME IS NOT NULL
		   AND DDIPS.avg_fragmentation_in_percent > 0
		   -- AND S.NAME = 'dbo'
		   -- AND T.NAME = 'Person'
	ORDER  BY DDIPS.avg_fragmentation_in_percent DESC

	


----------------------------------------------------------------------------------------------------------------------------------------------------------
--			DEFRAGMENTACE INDEXU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @TableName NVARCHAR(150)
	DECLARE @IndexName NVARCHAR(150)
	DECLARE @AvgFragmentation INT
	DECLARE @cmd  NVARCHAR(500)
	DECLARE CUR CURSOR 
	FOR SELECT QUOTENAME(OBJECT_SCHEMA_NAME(I.OBJECT_ID )) + '.' + QUOTENAME(OBJECT_NAME(i.OBJECT_ID))	AS TableName, QUOTENAME(i.name) AS IndexName, CONVERT(INT, st.avg_fragmentation_in_percent) AS AvgFragmentation
		FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL , NULL , NULL ) st
		JOIN sys.indexes i ON ST.object_id = i.object_id AND st.index_id = i.index_id
		WHERE st.page_count >= 500 /*Indexy o velikosti pod 4 MB nejsou dulezite*/AND st.index_id <> 0 /*HEAP*/ AND st.avg_fragmentation_in_percent > 5
		AND i.is_disabled = 0
	OPEN CUR
	WHILE 1 = 1
		BEGIN
			FETCH CUR INTO @TableName, @IndexName, @AvgFragmentation 
			IF @@FETCH_STATUS <> 0 BREAK
			IF @AvgFragmentation <= 30 SET @cmd = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE'
				ELSE SET @cmd = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD'
			EXEC (@cmd) PRINT CONVERT(NVARCHAR(20),GETDATE(),120) + ' ... ' + @cmd
		END
	CLOSE CUR
	DEALLOCATE CUR
	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			DOPORUCENI CHYBEJICICH INDEXU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT	TOP 25
			dm_mid.database_id AS DatabaseID,
			dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
			dm_migs.last_user_seek AS Last_User_Seek,
			OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
			'CREATE INDEX [IXe__' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '__'
			+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','__'),'[',''),']','') 
			+ CASE
				WHEN dm_mid.equality_columns IS NOT NULL
				AND dm_mid.inequality_columns IS NOT NULL THEN '__'
				ELSE ''
			END
			+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
			+ IIF(included_columns IS NOT NULL, '__I__', '')
			+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.included_columns,''),', ','__'),'[',''),']','') 
			+ ']'
			+ ' ON ' + dm_mid.statement
			+ ' (' + ISNULL (dm_mid.equality_columns,'')
			+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
			IS NOT NULL THEN ',' ELSE
			'' END
			+ ISNULL (dm_mid.inequality_columns, '')
			+ ')'
			+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
	FROM	sys.dm_db_missing_index_groups dm_mig
			INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
					ON dm_migs.group_handle = dm_mig.index_group_handle
			INNER JOIN sys.dm_db_missing_index_details dm_mid
					ON dm_mig.index_handle = dm_mid.index_handle
	WHERE	dm_mid.database_ID = DB_ID()
	ORDER	BY Avg_Estimated_Impact DESC
	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			NEPOUZIVANE INDEXY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Original Author: Pinal Dave 
	SELECT	TOP 25
			o.name AS ObjectName,
			i.name AS IndexName,
			i.index_id AS IndexID,
			dm_ius.user_seeks AS UserSeek,
			dm_ius.user_scans AS UserScans,
			dm_ius.user_lookups AS UserLookups,
			dm_ius.user_updates AS UserUpdates,
			p.TableRows,
			'DROP INDEX ' + QUOTENAME(i.name)
			+ ' ON ' + QUOTENAME(s.name) + '.'
			+ QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS 'drop statement'
	FROM	sys.dm_db_index_usage_stats dm_ius
			INNER JOIN sys.indexes i 
					ON i.index_id = dm_ius.index_id 
					AND dm_ius.OBJECT_ID = i.OBJECT_ID
			INNER JOIN sys.objects o 
					ON dm_ius.OBJECT_ID = o.OBJECT_ID
			INNER JOIN sys.schemas s
					ON o.schema_id = s.schema_id
			INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
						FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
					ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
	WHERE	OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
			AND dm_ius.database_id = DB_ID()
			AND i.type_desc = 'nonclustered'
			AND i.is_primary_key = 0
			AND i.is_unique_constraint = 0
	ORDER	BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			STATISTIKY NA KONKRETNI TABULCE
----------------------------------------------------------------------------------------------------------------------------------------------------------	

	SELECT sp.stats_id, 
		   name, 
		   filter_definition, 
		   last_updated, 
		   rows, 
		   rows_sampled, 
		   steps, 
		   unfiltered_rows, 
		   modification_counter
	FROM sys.stats AS stat
		 CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
	WHERE stat.object_id = OBJECT_ID('HumanResources.Employee');




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			AKTUALIZACE STATISTIK
----------------------------------------------------------------------------------------------------------------------------------------------------------	

	DECLARE @cmd  NVARCHAR(500)
	DECLARE @PocetTabulek INT
	DECLARE @Aktualni INT

	SELECT @PocetTabulek = COUNT(1) FROM sys.objects WHERE type = 'U'
	SET @Aktualni = 1

	DECLARE CUR CURSOR 
	FOR SELECT 'UPDATE STATISTICS ' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID )) + '.' + QUOTENAME(OBJECT_NAME(OBJECT_ID)) + ' WITH FULLSCAN' AS CMD FROM sys.objects WHERE type = 'U'
	OPEN CUR
	WHILE 1 = 1
		BEGIN
			FETCH CUR INTO @CMD
			IF @@FETCH_STATUS <> 0 BREAK
			EXEC (@cmd) 
			PRINT CONVERT(NVARCHAR(10), @Aktualni) + '/' + CONVERT(NVARCHAR(10), @PocetTabulek) + CHAR(9) + ' ... ' + CONVERT(NVARCHAR(20),GETDATE(),120) + ' ... ' + @cmd
			SET @Aktualni += 1
		END
	PRINT CHAR(13) + '----- A TO JE VSE, STATISTIKY JSOU ZAKTUALIZOVANY -----'
	CLOSE CUR
	DEALLOCATE CUR
	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			KONTROLA DUPLICITNICH INDEXU

--			NA ZAKLADE TETO KONTROLY ZJISTIME, ZDA NEBYLY VYTVORENY INDEXY S DUPLICITNIMI KLICI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('TEMPDB..#INDEXY ') IS NOT NULL DROP TABLE #INDEXY 
	CREATE TABLE #INDEXY (TABLENAME NVARCHAR(128), INDEXNAME NVARCHAR(128), SLOUPCE NVARCHAR(1000), INCSLOUPCE NVARCHAR(1000))
	GO

	DECLARE @TABULKA NVARCHAR(128), @INDEXNAME NVARCHAR(128), @OBJECT_ID INT, @INDEX_ID INT, @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX)

	DECLARE CUR CURSOR LOCAL FOR
	SELECT OBJECT_NAME(OBJECT_ID), OBJECT_ID, NAME, INDEX_ID 
		FROM SYS.INDEXES I

	OPEN CUR
	WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @TABULKA, @OBJECT_ID, @INDEXNAME ,@INDEX_ID 
		IF @@FETCH_STATUS <> 0 BREAK
		SET @SLOUPCE = ''
		SET @INCSLOUPCE = ''

		SELECT @SLOUPCE =  @SLOUPCE + SC.NAME + ', ' --CONVERT(NVARCHAR(10), COLUMN_ID) + '_' 
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 0
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID


		SELECT @INCSLOUPCE =  @INCSLOUPCE + SC.NAME + ', ' --CONVERT(NVARCHAR(10), COLUMN_ID) + '_' 
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 1
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID
		IF LEN(@INCSLOUPCE) > 0 SET @INCSLOUPCE =  LEFT(@INCSLOUPCE, LEN(@INCSLOUPCE) -1 )

	
		IF (LEN(@SLOUPCE)>=2) INSERT INTO #INDEXY SELECT @TABULKA, @INDEXNAME, LEFT(@SLOUPCE, LEN(@SLOUPCE) -1), @INCSLOUPCE
	END
	CLOSE CUR
	DEALLOCATE CUR

	SELECT I.* FROM #INDEXY I
	JOIN 
		(
		SELECT TABLENAME, SLOUPCE FROM #INDEXY 
		GROUP BY TABLENAME, SLOUPCE
		HAVING COUNT(1) > 1
		) IND
	ON I.TABLENAME = IND.TABLENAME AND I.SLOUPCE = IND.SLOUPCE
	ORDER BY 1, 2



	SELECT * FROM SYS.INDEXES WHERE NAME LIKE 'IXe%'

	SELECT * FROM SYS.INDEXES WHERE NAME LIKE 'IXe%00'
	GO