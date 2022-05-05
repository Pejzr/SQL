----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--															KONTROLA WAIT STATISTIK																		--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			NA ZAKLADE TETO KONTROLY ZJISTIME, NA CO SQL SERVER NEJCASTEJI CEKA
----------------------------------------------------------------------------------------------------------------------------------------------------------

/*
-- Script to Clear Wait Types
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
GO
*/

-- (C) Pinal Dave https://blog.sqlauthority.com/) 2021+

	SELECT 
		wait_type AS Wait_Type
		, wait_time_ms / 1000.0 AS Wait_Time_Seconds
		, waiting_tasks_count AS Waiting_Tasks_Count
		-- ,CAST((wait_time_ms / 1000.0)/waiting_tasks_count AS decimal(10,4)) AS AVG_Waiting_Tasks_Count,
		, wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS Percentage_WaitTime
		--,waiting_tasks_count * 100.0 / SUM(waiting_tasks_count) OVER() AS Percentage_Count
		, CAST(CONCAT('https://www.sqlshack.com/sql-server-wait-type-', REPLACE(wait_type, '_', '-')) as xml) as Description_Link
	FROM sys.dm_os_wait_stats
	WHERE wait_type NOT IN
		(N'BROKER_EVENTHANDLER',
		N'BROKER_RECEIVE_WAITFOR',
		N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH',
		N'BROKER_TRANSMITTER',
		N'CHECKPOINT_QUEUE',
		N'CHKPT',
		N'CLR_AUTO_EVENT',
		N'CLR_MANUAL_EVENT',
		N'CLR_SEMAPHORE',
		N'CXCONSUMER',
		N'DBMIRROR_DBM_EVENT',
		N'DBMIRROR_DBM_MUTEX',
		N'DBMIRROR_EVENTS_QUEUE',
		N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD',
		N'DIRTY_PAGE_POLL',
		N'DISPATCHER_QUEUE_SEMAPHORE',
		N'EXECSYNC',
		N'FSAGENT',
		N'FT_IFTS_SCHEDULER_IDLE_WAIT',
		N'FT_IFTSHC_MUTEX',
		N'HADR_CLUSAPI_CALL',
		N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
		N'HADR_LOGCAPTURE_WAIT',
		N'HADR_NOTIFICATION_DEQUEUE',
		N'HADR_TIMER_TASK',
		N'HADR_WORK_QUEUE',
		N'LAZYWRITER_SLEEP',
		N'LOGMGR_QUEUE',
		N'MEMORY_ALLOCATION_EXT',
		N'ONDEMAND_TASK_QUEUE',
		N'PARALLEL_REDO_DRAIN_WORKER',
		N'PARALLEL_REDO_LOG_CACHE',
		N'PARALLEL_REDO_TRAN_LIST',
		N'PARALLEL_REDO_WORKER_SYNC',
		N'PARALLEL_REDO_WORKER_WAIT_WORK',
		N'PREEMPTIVE_HADR_LEASE_MECHANISM',
		N'PREEMPTIVE_OS_FLUSHFILEBUFFERS',
		N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
		N'PREEMPTIVE_OS_AUTHORIZATIONOPS',
		N'PREEMPTIVE_OS_COMOPS',
		N'PREEMPTIVE_OS_CREATEFILE',
		N'PREEMPTIVE_OS_CRYPTOPS',
		N'PREEMPTIVE_OS_DEVICEOPS',
		N'PREEMPTIVE_OS_FILEOPS',
		N'PREEMPTIVE_OS_GENERICOPS',
		N'PREEMPTIVE_OS_LIBRARYOPS',
		N'PREEMPTIVE_OS_PIPEOPS',
		N'PREEMPTIVE_OS_QUERYREGISTRY',
		N'PREEMPTIVE_OS_VERIFYTRUST',
		N'PREEMPTIVE_OS_WAITFORSINGLEOBJECT',
		N'PREEMPTIVE_OS_WRITEFILEGATHER',
		N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
		N'PREEMPTIVE_XE_CALLBACKEXECUTE',
		N'PREEMPTIVE_XE_DISPATCHER',
		N'PREEMPTIVE_XE_GETTARGETSTATE',
		N'PREEMPTIVE_XE_SESSIONCOMMIT',
		N'PREEMPTIVE_XE_TARGETFINALIZE',
		N'PREEMPTIVE_XE_TARGETINIT',
		N'PWAIT_ALL_COMPONENTS_INITIALIZED',
		N'PWAIT_EXTENSIBILITY_CLEANUP_TASK',
		N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
		N'QDS_ASYNC_QUEUE',
		N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
		N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
		N'QDS_SHUTDOWN_QUEUE',
		N'REDO_THREAD_PENDING_WORK',
		N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE',
		N'SERVER_IDLE_CHECK',
		N'SOS_WORK_DISPATCHER',
		N'SLEEP_BPOOL_FLUSH',
		N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP',
		N'SLEEP_MASTERDBREADY',
		N'SLEEP_MASTERMDREADY',
		N'SLEEP_MASTERUPGRADED',
		N'SLEEP_MSDBSTARTUP',
		N'SLEEP_SYSTEMTASK',
		N'SLEEP_TASK',
		N'SLEEP_TEMPDBSTARTUP',
		N'SNI_HTTP_ACCEPT',
		N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH',
		N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
		N'SQLTRACE_WAIT_ENTRIES',
		N'STARTUP_DEPENDENCY_MANAGER',
		N'UCS_SESSION_REGISTRATION',
		N'VDI_CLIENT_OTHER',
		N'WAIT_FOR_RESULTS',
		N'WAIT_XTP_CKPT_CLOSE',
		N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
		N'WAIT_XTP_RECOVERY',
		N'WAITFOR',
		N'WAITFOR_TASKSHUTDOWN',
		N'XE_BUFFERMGR_ALLPROCESSED_EVENT',
		N'XE_DISPATCHER_JOIN',
		N'XE_TIMER_EVENT',
		N'XE_DISPATCHER_WAIT',
		N'XE_LIVE_TARGET_TVF'
		) AND wait_time_ms > 1
	ORDER BY Wait_Time_Seconds DESC
	-- ORDER BY Waiting_Tasks_Count DESC




	SELECT 
		  WAIT_TYPE AS [Typ èekání]
		, WAIT_TIME_MS/1000/60 AS [Celková doba v minutách]
		, WAITING_TASKS_COUNT AS [Poèet èekání]
		, WAIT_TIME_MS / WAITING_TASKS_COUNT /1000/60 AS [Prùmìrné èekání]
		, wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS Percentage_WaitTime
	FROM SYS.DM_OS_WAIT_STATS 
	WHERE WAITING_TASKS_COUNT > 0 
	ORDER BY 2 DESC

	/*
	NEJCASTEJSI PROBLEMOVE WAIT TYPY:

	ASYNC_NETWORK_IO	... TYPYCKY: RESULTSET ZUSTAVA NA SERVERU A JE PREDAVAN KLIENTOVI RADEK PO RADKU, NAMISTO TOHO, ABY SE CELY RESULTSET PREDAL NA KLIENTA A TEN SI PAK ZAZADAL O DALSI DATA
	CXPACKET			... PARALELISMUS. PROCES NADAVA, ZE UZ SKONCIL SVOJI PRACI A ZE MUSI CEKAT NA DOKONCENI PARALELNIHO PROCESU SE KTERYM DELAJI SPOLECNOU PRACI. 
							JDE OMEZIT SNIZENIM MAXDOP (NEMELO BY PREKROCIT 8), NEBO ZVYSENIM "COST TRESHOLD FOR PARALLELISM" (DEFAULT JE 5).
	LCK_M_IX			... CEKA NA TABULKU, NEBO STRAKU S IX LOCK-EM. TAKZE NEKDO PROVADI INSERT/UPDATE A OSTATNI MUSEJI CEKAT
	LCK_M_X				... BEZNE SE STAVA PRI ESKALACI ZAMKU, POPRIPADE NA ZAKLADE ISOLATION LEVEL (TJ. JAK DATA VIDI OSTATNI TRANSAKCE, KDY MOHOU CIST ...)
	PAGEIOLATCH_SH		... NACTENI STRANEK Z DISKU DO PAMETI. CASTO INDIKUJE POMALE DISKY. TAKY MUZE BYT MALA PAMET, NEBO BUFFER POOL JE PRILIS VYTIZENY
	PAGELATCH_EX		... 
	SOS_SCHEDULER_YIELD ... WORKLOAD UZ JE V PAMETI, ALE NEMA NAPOJENI NA ZDROJE, TAK DOBROVOLNE PREDAVA (UVOLNUJE) PROCESOR PRO OSTATNI.
	WRITELOG			... ZAPIS DO LOGU. NASTAVA VETSINOU, POKUD JE SOUBEZNE MNOHO ZAPISU DO LOGU A TEN SE NESTIHA ZAPISOVAT.
	*/




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			UKAZE, KDY BYLY STATISTIKY NAPOSLED RESETOVANY (BUD RESETEM SQL SERVERU NEBO SKRIPTEM)
----------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT
		[wait_type]
		, [wait_time_ms]
		, DATEADD(ms,-[wait_time_ms],getdate()) AS [Date/TimeCleared]
		, CASE
			WHEN [wait_time_ms] < 1000 THEN CAST([wait_time_ms] AS VARCHAR(15)) + ' ms'
			WHEN [wait_time_ms] between 1000 and 60000 THEN CAST(([wait_time_ms]/1000) AS VARCHAR(15)) + ' seconds'
			WHEN [wait_time_ms] between 60001 and 3600000 THEN CAST(([wait_time_ms]/60000) AS VARCHAR(15)) + ' minutes'
			WHEN [wait_time_ms] between 3600001 and 86400000 THEN CAST(([wait_time_ms]/3600000) AS VARCHAR(15)) + ' hours'
			WHEN [wait_time_ms] > 86400000 THEN CAST(([wait_time_ms]/86400000) AS VARCHAR(15)) + ' days'
		END [TimeSinceCleared]
	FROM [sys].[dm_os_wait_stats]
	WHERE [wait_type] = 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP';




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			VYTVORI LINK NA WEB S WAIT_STAT, KTERY UVEDEME DO PROMENNE @
----------------------------------------------------------------------------------------------------------------------------------------------------------

declare @WaitStat varchar(50) = 'PAGEIOLATCH_SH'
select @WaitStat, CAST(CONCAT('https://www.sqlshack.com/sql-server-wait-type-', REPLACE(@WaitStat, '_', '-')) as xml)
