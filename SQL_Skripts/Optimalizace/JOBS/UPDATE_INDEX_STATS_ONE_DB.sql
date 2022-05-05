
----------------------------------------------------------------------------------------------------------------------------------------------------------

--				VYTVORENI JOBU, KTERY BUDE PRAVIDELNE DEFRAGMENTOVAT INDEXY A AKTUALIZOVAT STATISTIKY

----------------------------------------------------------------------------------------------------------------------------------------------------------


IF SERVERPROPERTY ('EngineEdition') IN (4 /*Express*/)
	PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|     !!! Express edition. Cannot continue.       !!!        |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
IF EXISTS(SELECT * FROM MSDB..SYSJOBS WHERE NAME = 'ASOL Udrzba databaze') /*JOB UZ EXISTUJE*/
	PRINT CHAR(13) + CHAR(13) + REPLICATE('-',62) + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + '|          Job exists yet.                                   |' + CHAR(13) + '|' + REPLICATE(' ',60) + '|' + CHAR(13) + REPLICATE('-',62) 
ELSE 
BEGIN


	BEGIN TRANSACTION
	DECLARE @db_name NVARCHAR(150)
	DECLARE @activestartdate NVARCHAR(8)
	DECLARE @activestarttime NVARCHAR(6)

	SET @activestarttime = '230000' -- zacatek jobu je 23:00:00 ... Zacatek jobu by mel byt po Zaloha sys.dm_db_index_usage_stats, ale mimo pravidelne BACKUPy - nutno zkontrolovat !!!
	SET @db_name = N''  -----------------------------------------------------------------Nejprve najdi a dopln spravnou databazi !!! ---------------------------------------------------------- 
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
	/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4. 8. 2014 11:01:40 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASOL Udrzba databaze', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Udrzbova rutina, ktera defragmentuje indexy s vysokym stupnem fragmentace 
a aktualizuje statistiky vsech tabulek v databazi. 
Josef Korensky ASOL', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ASOL Udrzba databaze', 
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


SET NOCOUNT OFF
SET ANSI_NULLS ON
SET ANSI_NULL_DFLT_ON ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET IMPLICIT_TRANSACTIONS OFF
SET DATEFORMAT dmy
SET DATEFIRST 1
SET XACT_ABORT ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF


/*DEFRAGMENTACE INDEXU*/
DECLARE @TableName NVARCHAR(150)
DECLARE @IndexName NVARCHAR(150)
DECLARE @AvgFragmentation INT
DECLARE @cmd  NVARCHAR(500)
DECLARE CUR CURSOR 
FOR SELECT QUOTENAME(OBJECT_SCHEMA_NAME(I.OBJECT_ID )) + ''.'' + QUOTENAME(OBJECT_NAME(i.OBJECT_ID)) AS TableName, QUOTENAME(i.name) AS IndexName, CONVERT(INT, st.avg_fragmentation_in_percent) AS AvgFragmentation
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) st
	JOIN sys.indexes i ON ST.object_id = i.object_id AND st.index_id = i.index_id
	WHERE st.page_count >= 500 /*Indexy o velikosti pod 4 MB nejsou dulezite*/AND st.index_id <> 0 /*HEAP*/ AND st.avg_fragmentation_in_percent > 5
	AND i.is_disabled = 0
PRINT CHAR(13) + ''-----          START DEFRAGMENTACE INDEXU         -----'' + CHAR(13) 
OPEN CUR
WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @TableName, @IndexName, @AvgFragmentation 
		IF @@FETCH_STATUS <> 0 BREAK
		IF @AvgFragmentation <= 30 SET @cmd = ''ALTER INDEX '' + @IndexName + '' ON '' + @TableName + '' REORGANIZE''
			ELSE SET @cmd = ''ALTER INDEX '' + @IndexName + '' ON '' + @TableName + '' REBUILD''
		EXEC (@cmd) PRINT CHAR(13) + CONVERT(NVARCHAR(20),GETDATE(),120) + '' ... '' + @cmd
	END
CLOSE CUR
DEALLOCATE CUR

/*AKTUALIZACE STATISTIK*/
DECLARE @PocetStatistik INT
DECLARE @Aktualni INT

SELECT @PocetStatistik  = COUNT(1) FROM sys.objects WHERE type = ''U''
SET @Aktualni = 1

DECLARE CUR CURSOR  FOR 
SELECT ''UPDATE STATISTICS '' + QUOTENAME(sc.name) + ''.'' + QUOTENAME(so.name) + '' ('' + QUOTENAME(stat.name) + '') WITH FULLSCAN '' AS CMD 
FROM sys.stats as stat
CROSS APPLY sys.dm_db_stats_properties (stat.object_id, stat.stats_id) AS sp
JOIN sys.objects as so on stat.object_id=so.object_id
JOIN sys.schemas as sc on so.schema_id=sc.schema_id
where  isnull(modification_counter,0) > 0 or (rows<>rows_sampled)

PRINT CHAR(13) + ''-----          START AKTUALIZACE STATISTIK        -----'' + CHAR(13) 
OPEN CUR
WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @CMD
		IF @@FETCH_STATUS <> 0 BREAK
		EXEC (@cmd) 
		PRINT CHAR(13) + CONVERT(NVARCHAR(10), @Aktualni) + ''/'' + CONVERT(NVARCHAR(10), @PocetStatistik) + CHAR(9) + '' ... '' + CONVERT(NVARCHAR(20),GETDATE(),120) + '' ... '' + @cmd
		SET @Aktualni += 1
	END
PRINT CHAR(13) + ''-----                    KONEC                    -----''
CLOSE CUR
DEALLOCATE CUR
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
			@active_start_time=@activestarttime, --TJ 22:50 Start Jobu
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