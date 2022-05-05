
----------------------------------------------------------------------------------------------------------------------------------------------------------

--						3. VYTVORI JOB, KTERY BUDE LOGOVAT BLOKACE, TAK JAKO TO MAJI NA GREENU

----------------------------------------------------------------------------------------------------------------------------------------------------------

/****** Object:  Job [ASOL_LogBlokaci]    Script Date: 08.02.2019 10:17:49 ******/
DECLARE @job_id UNIQUEIDENTIFIER
SELECT @job_id = job_id FROM msdb..sysjobs where name = N'ASOL_Blokace_a_LogNeukoncenychTransakci'
IF @job_id IS NOT NULL
    EXEC msdb.dbo.sp_delete_job @job_id = @job_id, @delete_unused_schedule=1


DECLARE @database_name nvarchar(128) = N'Helios001' ------------------------------------ZADAT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
DECLARE @PocetDni INT = 60 -------------------------------------------------------------ZADAT pocet dni, ja dlouho ma job bezet

DECLARE @Stop INT
DECLARE @Start INT
SET @Stop =   CONVERT(INT, REPLACE(CONVERT(NVARCHAR(10), DATEADD(dd, @PocetDni, GETDATE()),120),'-',''))
SET @Start =   CONVERT(INT, REPLACE(CONVERT(NVARCHAR(10), GETDATE(),120),'-',''))


/****** Object:  Job [ASOL_LogBlokaci]    Script Date: 08.02.2019 10:17:49 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 08.02.2019 10:17:49 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ASOL_Blokace_a_LogNeukoncenychTransakci', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ASOL_LogBlokaci]    Script Date: 08.02.2019 10:17:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ASOL_Blokace_a_LogNeukoncenychTransakci', 
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

--				KONTROLA BLOKACI A NEUKONCENYCH TRANSAKCI
--
IF OBJECT_ID(''TEMPBLOCKEDPROCJKO'') IS NULL
	SELECT ''X'' AS Typ
	, SP.SPID,SP.KPID,SP.BLOCKED,SP.WAITTYPE,SP.WAITTIME,SP.LASTWAITTYPE,SP.WAITRESOURCE/*DBID*/,SP.UID,SP.CPU,SP.PHYSICAL_IO,SP.MEMUSAGE,SP.LOGIN_TIME,SP.LAST_BATCH
	,SP.ECID,SP.OPEN_TRAN,SP.STATUS,SP.SID,SP.HOSTNAME,SP.PROGRAM_NAME,SP.HOSTPROCESS,SP.CMD,SP.NT_DOMAIN,SP.NT_USERNAME,SP.NET_ADDRESS,SP.NET_LIBRARY,SP.LOGINAME
	,SP.CONTEXT_INFO,SP.SQL_HANDLE,SP.STMT_START,SP.STMT_END,SP.REQUEST_ID
	, SUBSTRING(QT.TEXT,0,CASE WHEN LEN(QT.TEXT) <= 5000 THEN LEN(QT.TEXT) ELSE 5000 END) AS ZACATEKSTMT
	, SUBSTRING(QT.TEXT,CASE WHEN SP.STMT_START/2 >= 0 THEN SP.STMT_START/2 + 1 ELSE 0 END, CASE WHEN SP.STMT_END/2 - SP.STMT_START/2 > 1 THEN SP.STMT_END/2 - SP.STMT_START/2 +1+1 ELSE 100000 END) AS AKTUALNIPRIKAZ
	, SE.TRANSACTION_ID, SE.ENLIST_COUNT, SE.IS_BOUND, SE.IS_LOCAL, SE.IS_USER_TRANSACTION, SE.TRANSACTION_DESCRIPTOR
	, SP.DBID, DB_NAME(SP.DBID) AS DBNAME
	, GETDATE() AS TIMEOCCUR 
    , 100.00 AS BufferHitRatio
	INTO TEMPBLOCKEDPROCJKO					
	FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT 
	LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
	WHERE BLOCKED > 0
	OR SPID IN (SELECT BLOCKED FROM SYS.SYSPROCESSES WITH (NOLOCK) WHERE BLOCKED > 0)
INSERT INTO TEMPBLOCKEDPROCJKO
SELECT ''X'', 0,0,0,0X0000,0,'''', '''', 0,0,0,0, GETDATE(), GETDATE(),0,0,'''', 0X0100, '''', '''', 0,'''','''','''','''','''','''',0X0100,0X0100,0,0,0,''---START LOGOVANI ---'',''---START LOGOVANI ---'',0,0,0,0,0,0X0000,0,'''',GETDATE(), 100.0
WHILE 1 = 1
BEGIN
	IF (SELECT COUNT(1) FROM TEMPBLOCKEDPROCJKO)>10000 
        DELETE TEMPBLOCKEDPROCJKO WHERE TIMEOCCUR < (SELECT MAX(TIMEOCCUR) FROM (SELECT TOP 1000 TIMEOCCUR FROM TEMPBLOCKEDPROCJKO ORDER BY TIMEOCCUR ) X)
    IF    
    (SELECT DATEADD(DAY,1,MAX(CONVERT(DATE, CONVERT(NVARCHAR(8),active_end_date)))) FROM msdb..sysjobs j
    JOIN msdb..sysjobschedules js ON j.job_id = js.job_id
    JOIN msdb..sysschedules s ON js.schedule_id = s.schedule_id
    WHERE j.name = N''ASOL_Blokace_a_LogNeukoncenychTransakci'') < GETDATE()
    BREAK		
	INSERT INTO TEMPBLOCKEDPROCJKO
	SELECT
    CASE WHEN (status = ''sleeping'' AND OPEN_TRAN > 0) THEN ''T'' ELSE ''B'' END AS Typ
	, SP.SPID,SP.KPID,SP.BLOCKED,SP.WAITTYPE,SP.WAITTIME,SP.LASTWAITTYPE,SP.WAITRESOURCE/*DBID*/,SP.UID,SP.CPU,SP.PHYSICAL_IO,SP.MEMUSAGE,SP.LOGIN_TIME,SP.LAST_BATCH
	,SP.ECID,SP.OPEN_TRAN,SP.STATUS,SP.SID,SP.HOSTNAME,SP.PROGRAM_NAME,SP.HOSTPROCESS,SP.CMD,SP.NT_DOMAIN,SP.NT_USERNAME,SP.NET_ADDRESS,SP.NET_LIBRARY,SP.LOGINAME
	,SP.CONTEXT_INFO,SP.SQL_HANDLE,SP.STMT_START,SP.STMT_END,SP.REQUEST_ID
	, SUBSTRING(QT.TEXT,0,CASE WHEN LEN(QT.TEXT) <= 5000 THEN LEN(QT.TEXT) ELSE 5000 END) AS ZACATEKSTMT
	, SUBSTRING(QT.TEXT,CASE WHEN SP.STMT_START/2 >= 0 THEN SP.STMT_START/2 + 1 ELSE 0 END, CASE WHEN SP.STMT_END/2 - SP.STMT_START/2 > 1 THEN SP.STMT_END/2 - SP.STMT_START/2 +1 +1 ELSE 100000 END) AS AKTUALNIPRIKAZ
	, SE.TRANSACTION_ID, SE.ENLIST_COUNT, SE.IS_BOUND, SE.IS_LOCAL, SE.IS_USER_TRANSACTION, SE.TRANSACTION_DESCRIPTOR
	, SP.DBID, DB_NAME(SP.DBID) AS DBNAME
	, GETDATE() AS TIMEOCCUR 
    ,(
    SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 as BufferCacheHitRatio
    FROM sys.dm_os_performance_counters  a
    JOIN  (SELECT cntr_value, OBJECT_NAME FROM sys.dm_os_performance_counters  
    WHERE counter_name = ''Buffer cache hit ratio base'' AND OBJECT_NAME LIKE ''%:Buffer Manager%'') b ON  a.OBJECT_NAME = b.OBJECT_NAME
    WHERE a.counter_name = ''Buffer cache hit ratio'' AND a.OBJECT_NAME LIKE ''%:Buffer Manager%''
    ) AS BufferHitRatio
	--INTO TEMPBLOCKEDPROCJKO					
	FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT ------------------------------------------------------------------------ POKUD CHCI "PRAZDNE RADKY", TAK NAHRADIT "CROSS APPLY" ZA "OUTER APPLY" 
	LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
	WHERE (status = ''sleeping'' AND OPEN_TRAN > 0)
    	OR (BLOCKED > 0 OR SPID IN (SELECT BLOCKED FROM SYS.SYSPROCESSES WITH (NOLOCK) WHERE BLOCKED > 0))
	PRINT ''AKTUALNI CAS: '' + CONVERT(VARCHAR(50),GETDATE(),120) + '' , ULOZENO ZAZNAMU: '' + CONVERT(VARCHAR(50),@@ROWCOUNT)
	WAITFOR DELAY ''00:00:05''
END
', 
		@database_name=@database_name, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Porad', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=@Start, 
		@active_end_date=@Stop, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'47d7e8cd-407b-4833-9318-214de52586a9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO