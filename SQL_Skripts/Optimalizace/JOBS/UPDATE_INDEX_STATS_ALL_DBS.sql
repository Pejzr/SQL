USE [msdb]
GO


DECLARE @jobId binary(16)

SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = N'ASOL_UdrzbaDatabazi')
IF (@jobId IS NOT NULL)
BEGIN
    EXEC msdb.dbo.sp_delete_job @jobId
END
GO


/****** Object:  Job [ASOL_UdrzbaDatabazi]    Script Date: 12.09.2016 8:53:54 ******/
BEGIN TRANSACTION

DECLARE @jobId binary(16)

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12.09.2016 8:53:55 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END


EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASOL_UdrzbaDatabazi', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Provede defragmentaci indexu, aktualizaci statistik a aktualizaci usage ve vsech uzivatelskych databazich. Josef Korensky, ASOL', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ASOL_UdrzbaDatabazi]    Script Date: 12.09.2016 8:53:55 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ASOL_UdrzbaDatabazi', 
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
DECLARE @db sysname		
DECLARE cur_dbs CURSOR fast_forward FOR 
/* NIZE UPRAVIT DOTAZ PRO KONKRETNI DATABAZE*/
SELECT name FROM master.sys.databases WHERE database_id > 4 AND state = 0 /*ONLINE*/
OPEN cur_dbs
FETCH NEXT FROM cur_dbs INTO @db
WHILE @@fetch_status = 0
	BEGIN
		print ''Reindexing Database: '' + @db
		EXEC(N''
				
			USE '' + @db + ''

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
DECLARE @cmd2  NVARCHAR(500)

DECLARE CUR CURSOR 
FOR SELECT QUOTENAME(OBJECT_SCHEMA_NAME(I.OBJECT_ID )) + ''''.'''' + QUOTENAME(OBJECT_NAME(i.OBJECT_ID)) AS TableName, QUOTENAME(i.name) AS IndexName, CONVERT(INT, st.avg_fragmentation_in_percent) AS AvgFragmentation
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) st
	JOIN sys.indexes i ON ST.object_id = i.object_id AND st.index_id = i.index_id
	WHERE st.page_count >= 10 /*Indexy o velikosti pod 80 KB nejsou dulezite*/AND st.index_id <> 0 /*HEAP*/ AND st.avg_fragmentation_in_percent > 5
	AND i.is_disabled = 0
PRINT CHAR(13) + ''''-----          START DEFRAGMENTACE INDEXU         -----'''' + CHAR(13) 
OPEN CUR
WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @TableName, @IndexName, @AvgFragmentation 
		IF @@FETCH_STATUS <> 0 BREAK
		IF @AvgFragmentation <= 30 SET @cmd = ''''ALTER INDEX '''' + @IndexName + '''' ON '''' + @TableName + '''' REORGANIZE''''
			ELSE SET @cmd = ''''ALTER INDEX '''' + @IndexName + '''' ON '''' + @TableName + '''' REBUILD''''
		EXEC (@cmd) PRINT CHAR(13) + CONVERT(NVARCHAR(20),GETDATE(),120) + '''' ... '''' + @cmd
	END
CLOSE CUR
DEALLOCATE CUR

/*AKTUALIZACE STATISTIK*/
DECLARE @PocetTabulek INT
DECLARE @Aktualni INT

SELECT @PocetTabulek = COUNT(1) FROM sys.objects WHERE type = ''''U''''
SET @Aktualni = 1

DECLARE CUR CURSOR 
FOR SELECT ''''UPDATE STATISTICS '''' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID )) + ''''.'''' + QUOTENAME(OBJECT_NAME(OBJECT_ID)) + '''' WITH FULLSCAN; DBCC UPDATEUSAGE(0,  ''''+ CHAR(39) + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID )) + ''''.'''' + QUOTENAME(OBJECT_NAME(OBJECT_ID)) + CHAR(39) +'''' ) WITH COUNT_ROWS,NO_INFOMSGS
'''' AS CMD FROM sys.objects WHERE type = ''''U''''
PRINT CHAR(13) + ''''-----          START AKTUALIZACE STATISTIK        -----'''' + CHAR(13) 
OPEN CUR
WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @CMD
		IF @@FETCH_STATUS <> 0 BREAK
		EXEC (@cmd) 
		PRINT CHAR(13) + CONVERT(NVARCHAR(10), @Aktualni) + ''''/'''' + CONVERT(NVARCHAR(10), @PocetTabulek) + CHAR(9) + '''' ... '''' + CONVERT(NVARCHAR(20),GETDATE(),120) + '''' ... '''' + @cmd
		SET @Aktualni = @Aktualni + 1
	END
PRINT CHAR(13) + ''''-----                    KONEC                    -----'''' + CHAR(13) + CHAR(13) + REPLICATE(REPLICATE(''''-'''', 60) + CHAR(13),3) + CHAR(13)
CLOSE CUR
DEALLOCATE CUR'')
		FETCH NEXT FROM cur_dbs INTO @db
	END
CLOSE cur_dbs
DEALLOCATE cur_dbs
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Kazdou noc', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160912, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO