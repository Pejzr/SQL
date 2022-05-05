----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--										NASTAVENI HARDWARE A NASTAVENI APLIKACI, KTERE MOHOU MIT DOPAD NA VYKON											--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			ZJISTIME PRACOVNI DATABAZI.
--			VYCHAZIME Z PREDPOKLADU, ZE V PRACOVNI DATABAZI JE PRIHLASENO PODSTATNE VICE UZIVATELU (PROCESU), NEZ V OSTATNICH DATABAZICH
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT DB_NAME(DBID) DB, COUNT(1) CNT FROM SYS.SYSPROCESSES WHERE SPID > 50 AND DBID > 4
	GROUP BY DB_NAME(DBID)
	ORDER BY CNT DESC

	USE XXX
	GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			KONTROLA NAPAJENI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 'Jeste zkontrolovat Power schema'




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			MÓD NAPÁJENÍ SERVERU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @show_advanced_options BIT
	DECLARE @xp_cmdshell BIT
	DECLARE @output table (result NVARCHAR(MAX))
	SELECT @show_advanced_options = CONVERT(BIT, value_in_use) FROM sys.configurations WHERE name = N'show advanced options'
	IF @show_advanced_options = 0 
	BEGIN
		EXEC sp_configure 'show advanced options', 1
		RECONFIGURE
	END
	SELECT @xp_cmdshell = CONVERT(BIT, value_in_use) FROM sys.configurations WHERE name = N'xp_cmdshell'
	IF @xp_cmdshell = 0 
	BEGIN
		EXEC sp_configure 'xp_cmdshell', 1
		RECONFIGURE
	END
	INSERT INTO @output (result)
	EXEC XP_CMDSHELL 'powercfg /L'
	IF @xp_cmdshell = 0 
		EXEC sp_configure 'xp_cmdshell', 0
	IF @show_advanced_options = 0 
		EXEC sp_configure 'show advanced options', 0
	IF @show_advanced_options = 0 OR @xp_cmdshell = 0 
		RECONFIGURE
	SELECT REPLACE(REPLACE(REPLACE(SUBSTRING(result, CHARINDEX('(', result), LEN(result)),')',' '),'(',''),'*','') AS [Mód napájení] FROM @output WHERE result LIKE '%*'




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			  KONTROLA ZDA JE NAINSTALOVANY POSLEDNI SP  
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT @@VERSION




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			  Kontrola CMTP levelu
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT * FROM SYS.DATABASES 

	/*
	ALTER DATABASE Helios001
	SET COMPATIBILITY_LEVEL = 150
	*/




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			  SCOPED CONFIGURATION (MAXDOP, LEGACY_CARDINALITY_ETIMATION...)
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT name, value FROM sys.database_scoped_configurations  

	SELECT name, value  
		FROM tempdb.sys.database_scoped_configurations  

	SELECT name, value  
		FROM model.sys.database_scoped_configurations  

	/*
		USE Helios001
		ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  
		ALTER DATABASE     SCOPED CONFIGURATION           SET MAXDOP = 2;
	 
		USE tempdb ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  
		USE model ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  

		RECONFIGURE
		GO
	*/

	/*
		QUERY_OPTIMIZER_HOTFIXES
			- Je dulezity pouze pokud mame SQL Server 2016 a novejsi a mame tam nizsi CMTP level (napr.: 2017 -> 130, 2016 -> 100)
			- Zapina nebo vypina zmeny chovani dotazu po instalaci noveho update (tzn.: pokud nainstalujeme novy CU nebo SP,
			  v pripade hodnoty OFF nebude dotaz menit sve chovani jako je treba jiny exekucni plan)

		LEGACY_CARDINALITY_ESTIMATION
			- Odhaduje, kolik radku muj dotaz vrati
			- Query optimalizér nastaví odhad mohutnosti pro SQL Server 2012 a døívìjší, nezávisle na Compability levelu databáze (CMTP)

		MAXDOP
			- Pocet pouzitelnych procesoru (melo by byt nastaveno jako 1/2 poctu jader v jednom node)
			- Konkrétní èíslo nastavit pouze pro primární databáze
			- Nastavit 0 pro všechny druhotné databáze, jako je Reporting Queries

		PARAMETER_SNIFFING
			- Vytvori optimalni plan pro proceduru na zaklade toho, s jakymi hodnotamy v parametrech se poprve volala

		Detailní vysvìtlení:
			https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-scoped-configuration-transact-sql?view=sql-server-ver15#arguments
	*/


	SELECT 'Nezapomen na: ALTER DATABASE Helios001 SET TARGET_RECOVERY_TIME = 0 SECONDS;'
	SELECT 'Nezapomen na: ALTER DATABASE model SET TARGET_RECOVERY_TIME = 0 SECONDS;'
	SELECT 'Nezapomen na: ALTER DATABASE tempdb SET TARGET_RECOVERY_TIME = 0 SECONDS;'
	
	/*
		SELECT name,target_recovery_time_in_seconds FROM sys.databases;
	*/

----------------------------------------------------------------------------------------------------------------------------------------------------------
--			    VYUŽITÍ JADER (ZDA JSOU ONLINE - SOUVISÍ S LICENCOVANIM)  
----------------------------------------------------------------------------------------------------------------------------------------------------------

	EXEC sys.xp_readerrorlog 0, 1, N'detected', N'socket';


	IF OBJECT_ID('tempdb..#errorLog') IS NOT NULL DROP TABLE #errorLog
	CREATE TABLE #errorLog (LogDate DATETIME, ProcessInfo VARCHAR(64), [Text] VARCHAR(MAX));
	INSERT INTO #errorLog
	EXEC sp_readerrorlog 6 -- specify the log number or use nothing for active error log
	SELECT * FROM #errorLog a WHERE Text LIKE '%detect%'

	select  
	parent_node_id as 'NUMA',
	cpu_id as 'CPU',
	scheduler_id as 'SCHEDULER',
	status,
	is_online,
	current_tasks_count
	from sys.dm_os_schedulers
	order by scheduler_id




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			    VYBRANE PARAMETRY DATABAZE
----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	SELECT 
	 CASE WHEN collation_name <> 'Czech_CI_AS'		THEN 'PROBLEM: ' + collation_name ELSE collation_name																	END collation_name
	,CASE WHEN is_auto_shrink_on <> 0				THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_shrink_on) ELSE CONVERT(NVARCHAR(10), is_auto_shrink_on)				END is_auto_shrink_on
	,CASE WHEN recovery_model <> 3					THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), recovery_model) ELSE CONVERT(NVARCHAR(10), recovery_model)					END recovery_model
	,CASE WHEN recovery_model_desc <> 'SIMPLE'		THEN 'PROBLEM: ' +  recovery_model_desc ELSE recovery_model_desc														END recovery_model_desc
	,CASE WHEN is_auto_create_stats_on <> 1			THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_create_stats_on) ELSE CONVERT(NVARCHAR(10), is_auto_create_stats_on)	END is_auto_create_stats_on
	,CASE WHEN is_auto_update_stats_on <> 1			THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_update_stats_on) ELSE CONVERT(NVARCHAR(10), is_auto_update_stats_on)	END is_auto_update_stats_on
	,CASE WHEN is_auto_update_stats_async_on <> 0	THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_update_stats_async_on) ELSE CONVERT(NVARCHAR(10), is_auto_update_stats_async_on) END is_auto_update_stats_async_on
	FROM SYS.DATABASES WHERE database_id = DB_ID()




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			    VYBRANE PARAMETRY DATABAZOVYCH SOUBORU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
	name, 
	CASE WHEN is_percent_growth = 1 THEN CONVERT(NVARCHAR(5), growth) + '%'
	ELSE CONVERT(NVARCHAR(5), growth/128) + 'MB' END RustDB
	, CONVERT(NVARCHAR(5), size/128/1024) + 'GB' VelikostGB
	, CONVERT(NVARCHAR(5), size/128) + 'MB' VelikostMB
	, CASE WHEN max_size = -1 THEN 'Neomezeno' WHEN max_size = 0 THEN 'Rust nepovolen'
	ELSE CONVERT(NVARCHAR(5), max_size/128/1024) + 'GB' END MaxVelikost
	, type
	, type_desc
	, physical_name
	, CASE	WHEN (is_percent_growth = 1 AND growth < 10)	THEN 'PROBLEM - Prilis maly rust!'
			WHEN (is_percent_growth = 0 AND growth < 1024/8*10)	THEN 'PROBLEM - Prilis maly rust!'
			ELSE 'OK'
		END AS INFO
	 FROM SYS.database_files s




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      VYUZITI PAMETI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	select physical_memory_in_use_kb/1024/1024 AS physical_memory_in_use_GB, * from sys.dm_os_process_memory




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      DATABAZE CELKEM
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @total_buffer INT;
	SELECT @total_buffer = cntr_value
	   FROM sys.dm_os_performance_counters 
	   WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
	   AND counter_name = 'Total Pages';
	WITH src AS
	(
	   SELECT 
		   database_id, db_buffer_pages = COUNT_BIG(*)
		   FROM sys.dm_os_buffer_descriptors
		   --WHERE database_id BETWEEN 5 AND 32766
		   GROUP BY database_id
	)
	SELECT
	   [db_name] = CASE [database_id] WHEN 32767 
		   THEN 'Resource DB' 
		   ELSE DB_NAME([database_id]) END,
	   db_buffer_pages,
	   db_buffer_MB = db_buffer_pages / 128,
	   db_buffer_percent = CONVERT(DECIMAL(6,3), 
		   db_buffer_pages * 100.0 / @total_buffer)
	FROM src
	ORDER BY db_buffer_MB DESC;



	
----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      A JESTE KONKRETNI DB A KONKRETNI OBJEKTY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	USE XXX;
	GO

	;WITH src AS
	(
	   SELECT
		   [Object] = o.name,
		   [Type] = o.type_desc,
		   [Index] = COALESCE(i.name, ''),
		   [Index_Type] = i.type_desc,
		   p.[object_id],
		   p.index_id,
		   au.allocation_unit_id
	   FROM
		   sys.partitions AS p
	   INNER JOIN
		   sys.allocation_units AS au
		   ON p.hobt_id = au.container_id
	   INNER JOIN
		   sys.objects AS o
		   ON p.[object_id] = o.[object_id]
	   INNER JOIN
		   sys.indexes AS i
		   ON o.[object_id] = i.[object_id]
		   AND p.index_id = i.index_id
	   WHERE
		   au.[type] IN (1,2,3)
		   AND o.is_ms_shipped = 0
	)
	SELECT
	   src.[Object],
	   src.[Type],
	   src.[Index],
	   src.Index_Type,
	   buffer_pages = COUNT_BIG(b.page_id),
	   buffer_mb = COUNT_BIG(b.page_id) / 128
	FROM
	   src
	INNER JOIN
	   sys.dm_os_buffer_descriptors AS b
	   ON src.allocation_unit_id = b.allocation_unit_id
	WHERE
	   b.database_id = DB_ID()
	GROUP BY
	   src.[Object],
	   src.[Type],
	   src.[Index],
	   src.Index_Type
	ORDER BY
	   buffer_pages DESC;




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      DOSTUPNA PAMET NA SERVERU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT [total_physical_memory_kb] / 1024 AS [Total_Physical_Memory_In_MB]
		,[available_page_file_kb] / 1024 AS [Available_Physical_Memory_In_MB]
		,[total_page_file_kb] / 1024 AS [Total_Page_File_In_MB]
		,[available_page_file_kb] / 1024 AS [Available_Page_File_MB]
		,[kernel_paged_pool_kb] / 1024 AS [Kernel_Paged_Pool_MB]
		,[kernel_nonpaged_pool_kb] / 1024 AS [Kernel_Nonpaged_Pool_MB]
		,[system_memory_state_desc] AS [System_Memory_State_Desc]
	FROM [master].[sys].[dm_os_sys_memory]




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      MINIMALNI A MAXIMALNI PAMET URCENA PRO SQL SERVER
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT [name] AS [Name]
		,[configuration_id] AS [Number]
		,[minimum] AS [Minimum]
		,[maximum] AS [Maximum]
		,[is_dynamic] AS [Dynamic]
		,[is_advanced] AS [Advanced]
		,[value] AS [ConfigValue]
		,[value_in_use] AS [RunValue]
		,[description] AS [Description]
	FROM [master].[sys].[configurations]
	WHERE NAME IN ('Min server memory (MB)', 'Max server memory (MB)')




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      CELKOVA VELIKOST VSECH ONLINE DATABAZI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT type_desc, CONVERT(INT, SUM(SIZE)  * 8.0 / 1024 /1024) SIZE_GB, CONVERT(INT, SUM(SIZE)  * 8.0 / 1024) SIZE_MB
		FROM SYS.MASTER_FILES
		WHERE database_id in (select database_id from sys.databases where state_desc = 'ONLINE')
		GROUP BY type_desc
		ORDER BY 1 DESC




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      VELIKOSTI A PARAMETRY JEDNOTLIVYCH DATABAZI NA SERVERU (POUZE ONLINE DATABAZE)
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT d.name, CASE 
	WHEN Data.Rust_MB < 50 AND Data.Rust_Percent = 0 OR Data.Rust_MB = 0 AND Data.Rust_Percent < 5 THEN 'Prilis maly rust DATA'
	WHEN Logy.Rust_MB < 50 AND Logy.Rust_Percent = 0 OR Logy.Rust_MB = 0 AND Logy.Rust_Percent < 5 THEN 'Prilis maly rust LOG'
	WHEN collation_name <> 'Czech_CI_AS' THEN 'Nespravna collation'
	WHEN is_auto_shrink_on <> 0 THEN 'Zapnuty Autoshrink'
	WHEN is_auto_create_stats_on <> 1 THEN 'vypnute is_auto_create_stats_on'
	WHEN is_auto_update_stats_on <> 1 THEN 'vypnute is_auto_update_stats_on'
	WHEN is_auto_update_stats_async_on <> 0 THEN 'zapnute is_auto_update_stats_async_on'
	ELSE '---OK---' END AS Stav
	, Data.SIZE_MB AS Data_MB, Data.Rust_MB, Data.Rust_Percent, Logy.SIZE_MB AS LOG_MB, Logy.Rust_MB, Logy.Rust_Percent, collation_name, is_auto_shrink_on
	, d.state_desc, recovery_model_desc, is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on, create_date, compatibility_level
	FROM SYS.databases d
	LEFT JOIN (SELECT database_id, CONVERT(INT, SUM(SIZE) * 8.0 / 1024) AS SIZE_MB, SUM(CASE WHEN is_percent_growth = 0 THEN growth ELSE 0 END) *8 / 1024 AS Rust_MB, AVG(CASE WHEN is_percent_growth = 1 THEN growth ELSE 0 END) AS Rust_Percent 
	FROM SYS.MASTER_FILES WHERE type_desc = 'ROWS' GROUP BY database_id
	) Data on d.database_id = Data.database_id 
	LEFT JOIN (SELECT database_id, CONVERT(INT, SUM(SIZE) * 8.0 / 1024) AS SIZE_MB, SUM(CASE WHEN is_percent_growth = 0 THEN growth ELSE 0 END) *8 / 1024 AS Rust_MB, AVG(CASE WHEN is_percent_growth = 1 THEN growth ELSE 0 END) AS Rust_Percent 
	FROM SYS.MASTER_FILES WHERE type_desc = 'LOG' GROUP BY database_id
	) Logy on d.database_id = Logy.database_id 
	WHERE d.state_desc  = 'ONLINE'
	ORDER BY Data.SIZE_MB DESC




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			      ARCHIVACE ZMEN
----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	select 
	convert(int,ArchivaceZmenDenik ) + convert(int, ArchivaceZmenKmenZbozi ) + convert(int, ArchivaceZmenDokZbo ) + convert(int, ArchivaceZmenPokladna ) + convert(int, ArchivaceZmenNC ) + convert(int, ArchivaceZmenKontaktJednani ) + convert(int, ArchivaceZmenBankSp
	  ) + convert(int, ArchivaceZmenZamMzd ) + convert(int, ArchivaceZmenCisZam ) + convert(int, ArchivaceZmenMzdOdpPolMzd ) + convert(int, ArchivaceZmenDosleObjH20 ) + convert(int, ArchivaceZmenSkupinaZbozi ) + convert(int, ArchivaceZmenDosleObjH02)
	 AS ArchivaceZmenCelkem
	 , ArchivaceZmenDenik , ArchivaceZmenKmenZbozi, ArchivaceZmenDokZbo, ArchivaceZmenPokladna, ArchivaceZmenNC, ArchivaceZmenKontaktJednani, ArchivaceZmenBankSp
	 , ArchivaceZmenZamMzd, ArchivaceZmenCisZam, ArchivaceZmenMzdOdpPolMzd, ArchivaceZmenDosleObjH20, ArchivaceZmenSkupinaZbozi, ArchivaceZmenDosleObjH02
	 from TabHGlob
