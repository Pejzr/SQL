----------------------------------------------------------------------------------------------------------------------------------------------------------

--				VYTVORENI JOBU, KTERY BUDE ZALOHOVAT SYSTEMOVE VIEW: SYS.DM_DB_INDEX_USAGE_STATS
--				ACKOLIM MS TVRDI, ZE STATISTIKY V TOMTO VIEW SE MAZOU PRI RESTARTU SERVERU, NEBO PRO ODPOJENI DB, TAK REALNE SE ZAZNAMY NULUJI I PRI REBUILDU INDEXU
--				TOTO SE DEJE JAK V MSSQL 2012, TAK I V MSSQL 2014.
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, JESTLI NEEXISTUJI INDEXY, KTERYCH BY BYLO VHODNE SE ZBAVIT (DISABLOVAT)

----------------------------------------------------------------------------------------------------------------------------------------------------------


IF SERVERPROPERTY ('EngineEdition') IN (4 /*Express*/)
	PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|     !!! Express edition. Cannot continue.       !!!        |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
IF EXISTS(SELECT * FROM MSDB..SYSJOBS WHERE NAME = 'ASOL Zaloha statistik vyuziti') /*JOB UZ EXISTUJE*/
	PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|          Job exists yet.                                   |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
ELSE 
BEGIN


	BEGIN TRANSACTION
	DECLARE @db_name NVARCHAR(150)
	DECLARE @activestartdate NVARCHAR(8)
	DECLARE @activestarttime NVARCHAR(6)

	SET @activestarttime = '225000' -- zacatek jobu je 22:50:00 ... JOB BY MEL ZACIT PAR MINUT PRED UDRZBOU DATABAZE (REBUILD INDEXU ...)
	SET @db_name = N'' -----------------------------------------------------------------Nejprve najdi a dopln spravnou databazi !!! ---------------------------------------------------------- 
	/*
	SELECT DB_NAME(DBID), COUNT(1) CNT FROM SYS.SYSPROCESSES WHERE SPID > 50 AND DBID > 4
	GROUP BY DB_NAME(DBID)
	ORDER BY CNT DESC
	*/

	IF @db_name = N''
		BEGIN
		PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|     !!! Nejprve najdi a dopln spravnou databazi !!!        |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
		GOTO QuitWithRollback
		END

	SET @activestartdate = CONVERT(NVARCHAR,GETDATE(),112)
	
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASOL Zaloha statistik vyuziti', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Protoze MS ma v SQL od verze 2012 chybu, kterou nehodla resit a ktera likviduje zaznamy v SYS.DM_DB_INDEX_USAGE_STATS po kazdem rebuildu indexu, zalohuje tento job aktualni informace.
	Na zaklade techto informaci lze rozhodnout o tom, ktere indexy disablovat.
	Pak se zalohuji statistiky vyuziti exekucnich planu dotazu a procedur.
	sys.dm_db_index_usage_stats, sys.dm_exec_query_stats, sys.dm_exec_procedure_stats

	Josef Korensky ASOL
	', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Zaloha sys.dm_db_index_usage_stats, sys.dm_exec_query_stats a sys.dm_exec_procedure_stats', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'
	IF OBJECT_ID(''SYS_DM_DB_INDEX_USAGE_STATS_JKO'') IS NULL CREATE TABLE SYS_DM_DB_INDEX_USAGE_STATS_JKO (Vyuziti INT, Aktualizace INT, DatabaseName NVARCHAR(128), TableName NVARCHAR(128), IndexName NVARCHAR(128), DateSave DATETIME DEFAULT (GETDATE()))
	DELETE SYS_DM_DB_INDEX_USAGE_STATS_JKO WHERE DateSave < DATEADD(MONTH, -6, GETDATE())	/*Smaz stare zaznamy*/
	INSERT INTO SYS_DM_DB_INDEX_USAGE_STATS_JKO (Vyuziti, Aktualizace, DatabaseName , TableName, IndexName)
		SELECT USER_SCANS + USER_LOOKUPS + USER_SEEKS + SYSTEM_SCANS + SYSTEM_LOOKUPS + SYSTEM_SEEKS AS VYUZITI
			, USER_UPDATES + SYSTEM_UPDATES AS AKTUALIZACE
			, DB_NAME() AS DatabaseName, OBJECT_NAME(S.OBJECT_ID) AS TABLENAME, I.NAME AS INDEXNAME
		FROM	SYS.INDEXES AS I
			LEFT JOIN SYS.DM_DB_INDEX_USAGE_STATS AS S ON I.OBJECT_ID = S.OBJECT_ID AND I.INDEX_ID = S.INDEX_ID		-- LEFT JOIN PROTO, ABY SE UKAZALY I JESTE NEPOUZITE INDEXY
		WHERE	OBJECTPROPERTY(S.[OBJECT_ID],''ISUSERTABLE'') = 1
		   AND S.DATABASE_ID = DB_ID()
		   AND I.TYPE <> 0 /*IS NOT HEAP*/
		   AND IS_UNIQUE = 0
		   AND IS_PRIMARY_KEY = 0
		   AND IS_UNIQUE_CONSTRAINT = 0

-------------------------------

IF OBJECT_ID(''SYS_DM_EXEC_QUERY_STATS_JKO'') IS NULL CREATE TABLE SYS_DM_EXEC_QUERY_STATS_JKO
	(SQLTEXT NVARCHAR(MAX), EXECUTION_COUNT BIGINT, TOTAL_WORKER_TIME BIGINT, LAST_WORKER_TIME BIGINT, QUERY_PLAN XML
	,CREATION_TIME DATETIME, LAST_EXECUTION_TIME DATETIME, TEXT NVARCHAR(MAX), DBID SMALLINT, INSERTDATE DATETIME)

IF OBJECT_ID(''SYS_DM_EXEC_PROCEDURE_STATS_JKO'') IS NULL CREATE TABLE SYS_DM_EXEC_PROCEDURE_STATS_JKO
	(DATABASE_ID INT, OBJECT_ID INT, NAME NVARCHAR(128), TYPE CHAR(2), EXECUTION_COUNT BIGINT, TOTAL_WORKER_TIME BIGINT, QUERY_PLAN XML 
	, TEXT NVARCHAR(MAX), CACHED_TIME DATETIME, LAST_EXECUTION_TIME DATETIME, INSERTDATE DATETIME)

DELETE SYS_DM_EXEC_QUERY_STATS_JKO WHERE DATEDIFF(DAY, INSERTDATE, GETDATE()) > 30
DELETE SYS_DM_EXEC_PROCEDURE_STATS_JKO WHERE DATEDIFF(DAY, INSERTDATE, GETDATE()) > 30


UPDATE SYS_DM_EXEC_QUERY_STATS_JKO SET QUERY_PLAN = NULL WHERE SQLTEXT IN
(
	SELECT TOP 50 SUBSTRING(QT.TEXT, (QS.STATEMENT_START_OFFSET/2)+1, ((CASE QS.STATEMENT_END_OFFSET WHEN -1 THEN DATALENGTH(QT.TEXT) ELSE QS.STATEMENT_END_OFFSET END - QS.STATEMENT_START_OFFSET)/2)+1) AS SQLTEXT
	FROM SYS.DM_EXEC_QUERY_STATS QS
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE())
	AND QT.TEXT NOT LIKE ''%SYS_DM_EXEC_QUERY_STATS_JKO%''
	ORDER BY TOTAL_WORKER_TIME DESC

)	AND QUERY_PLAN IS NOT NULL


UPDATE SYS_DM_EXEC_PROCEDURE_STATS_JKO SET QUERY_PLAN = NULL WHERE OBJECT_ID IN
(
	SELECT TOP 50 QS.OBJECT_ID
	FROM SYS.DM_EXEC_PROCEDURE_STATS QS
	LEFT JOIN SYS.SYSOBJECTS SO ON QS.OBJECT_ID = SO.ID
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE()) 
	AND QT.TEXT NOT LIKE ''%SYS_DM_EXEC_PROCEDURE_STATS_JKO%''
	ORDER BY TOTAL_WORKER_TIME DESC
)	AND QUERY_PLAN IS NOT NULL

INSERT INTO SYS_DM_EXEC_QUERY_STATS_JKO
	SELECT TOP 50 SUBSTRING(QT.TEXT, (QS.STATEMENT_START_OFFSET/2)+1, ((CASE QS.STATEMENT_END_OFFSET WHEN -1 THEN DATALENGTH(QT.TEXT) ELSE QS.STATEMENT_END_OFFSET END - QS.STATEMENT_START_OFFSET)/2)+1) AS SQLTEXT
	, QS.EXECUTION_COUNT, QS.TOTAL_WORKER_TIME, QS.LAST_WORKER_TIME, QP.QUERY_PLAN, QS.CREATION_TIME, QS.LAST_EXECUTION_TIME, QT.TEXT, QT.DBID, GETDATE()
	FROM 
	SYS.DM_EXEC_QUERY_STATS QS
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE())
	AND QT.TEXT NOT LIKE ''%SYS_DM_EXEC_QUERY_STATS_JKO%''
	ORDER BY TOTAL_WORKER_TIME DESC

INSERT INTO SYS_DM_EXEC_PROCEDURE_STATS_JKO
	SELECT TOP 50 QS.DATABASE_ID, QS.OBJECT_ID, SO.NAME, QS.TYPE, QS.EXECUTION_COUNT, QS.TOTAL_WORKER_TIME, QP.QUERY_PLAN, QT.TEXT, QS.CACHED_TIME, QS.LAST_EXECUTION_TIME, GETDATE() INSERTDATE
	FROM 
	(
	SELECT * FROM SYS.DM_EXEC_PROCEDURE_STATS
	UNION ALL
	SELECT * FROM SYS.DM_EXEC_TRIGGER_STATS
	) AS QS
	LEFT JOIN SYS.SYSOBJECTS SO ON QS.OBJECT_ID = SO.ID
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE()) 
	AND QT.TEXT NOT LIKE ''%SYS_DM_EXEC_PROCEDURE_STATS_JKO%''
	ORDER BY TOTAL_WORKER_TIME DESC
	', 
			@database_name=@db_name, 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EveryDay', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date= @activestartdate, --Dnesni den
			@active_end_date=99991231, 
			@active_start_time=@activestarttime, --225000, --TJ 22:50 Start Jobu
			@active_end_time=235959
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	COMMIT TRANSACTION
	PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|          Job created correctly.                            |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
	GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
END
GO


----------------------------------------------------------------

--				POKUD UZ JE NASAZENY ZALOHUJICI JOB, TAK PRO ANALYZU POUZIT:

SELECT SQLTEXT, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MIN(CREATION_TIME) CREATION_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME, COUNT(1) CNT 
FROM SYS_DM_EXEC_QUERY_STATS_JKO WHERE DBID = DB_ID()
GROUP BY SQLTEXT
ORDER BY TOTAL_WORKER_TIME DESC

SELECT NAME, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MIN(CACHED_TIME) CREATION_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME, COUNT(1) CNT 
FROM SYS_DM_EXEC_PROCEDURE_STATS_JKO WHERE DATABASE_ID = DB_ID()
GROUP BY NAME
ORDER BY TOTAL_WORKER_TIME DESC

----------------------------------------------------------------

--				ANALYZA UDAJU ZAZNAMENANYCH JOBEM + NAVRH INDEXU PRO DISABLOVANI
--				ANALYZA BY MELA PROBEHNOUT NEJDRIVE 1 TYDEN PO NASAZENI JOBU, ABY BYLA SMYSLUPLNA


SELECT SUM(convert(bigint,Vyuziti)) Vyuziti, SUM(convert(bigint,Aktualizace)) Aktualizace, COUNT(1) CNT, DatabaseName, TableName, IndexName, CONVERT(date,MIN(DateSave)) PrvniUlozeni, CONVERT(date,MAX(DateSave)) PosledniUlozeni, 
CASE 
	WHEN i.is_disabled = 0 AND i.is_primary_key = 0 AND i.is_unique = 0 AND i.is_unique_constraint = 0 AND SUM(convert(bigint,Vyuziti))*10 < SUM(convert(bigint,Aktualizace)) 
	THEN 'ALTER INDEX ' + IndexName + ' ON ' + TableName + ' DISABLE'
	WHEN i.is_disabled = 1 THEN 'Uz je disablovany'
	ELSE ''
	END AS CMD
FROM SYS_DM_DB_INDEX_USAGE_STATS_JKO jko
JOIN sys.indexes i ON jko.IndexName = i.name and i.object_id = OBJECT_ID(jko.TableName)
--WHERE i.name LIKE 'IXe%'
GROUP BY DatabaseName, TableName, IndexName, is_disabled, i.is_primary_key, is_unique, is_unique_constraint 
ORDER BY 1, 2 DESC


----------------------------------------------------------------

--				KONTROLA, ZDA JE MOZNE INDEXY OPRAVDU DISABLOVAT
--				JELIKOZ HELIOS SI HLIDA VLASTNI INDEXY, NENI MOZNE INDEXY DROPNOUT, PROTOZE PRI NASLEDUJICI KONTROLE BY BYLY ZNOVU VYTVORENY
--				JE TEDY POUZE MOZNE INDEXY DISABLOVAT
--				NICMENE SE MUZE STAT, ZE INDEX JE POUZITY PRIMO V ZAPSANEM SELECTU JAKO HINT, PAK BY PO DISABLOVANI HLASIL HELIOS CHYBU
--				PROTO JE NUTNE ZKONTROLOVAT ZDA SE NAZEV INDEXU NEVYSKYTUJE VE ZDROJOVYCH KODECH !!!


----------------------------------------------------------------

--				PRO PREDANI VYSLEDKU K ANALYZE SPUSTIT (NEJDRIVE 1 TYDEN PO SPUSTENI JOBU):


SELECT * FROM SYS_DM_DB_INDEX_USAGE_STATS_JKO jko
JOIN sys.indexes i ON jko.IndexName = i.name
--VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT