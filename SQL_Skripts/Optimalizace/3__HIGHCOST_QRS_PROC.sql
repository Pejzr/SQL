----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--													KONTROLA NEJNAROCNEJSICH DOTAZU / PROCEDUR															--
--																																						--
--					NA ZAKLADE TETO KONTROLY ZJISTIME, KTERE DOTAZY/PROCEDURY SPOTREBOVAVAJI NEJVICE CPU CASU A JEJICH EXEKUCNI PLAN.					--
--								VYSLEDKY JE NUTNE BRAT S REZERVOU, PROTOZE "ZDROJOVA DATA" SE KUMULUJI OD KDOVIKDY										--
--					PO TETO KONTROLE JE MOZNE ZKONTROLOVAT STATISTIKY NA PROBLEMOVYCH TABULKACH, POPRIPADE NAVRHNOUT DOPORUCENE INDEXY					--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			NEJPRVE DOTAZY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT TOP 50
		qt.dbid,  DB_NAME(qt.dbid) AS DB--, ms.dbid, DB_NAME(convert(int,ms.dbid)) AS DBMS
		,SUBSTRING(QT.TEXT, (QS.STATEMENT_START_OFFSET/2)+1,
		((CASE QS.STATEMENT_END_OFFSET
		WHEN -1 THEN DATALENGTH(QT.TEXT)
		ELSE QS.STATEMENT_END_OFFSET
		END - QS.STATEMENT_START_OFFSET)/2)+1) AS SQLTEXT,
		QS.EXECUTION_COUNT,
		QS.TOTAL_WORKER_TIME,
		QP.QUERY_PLAN
		, qs.creation_time
		, qs.last_execution_time
		, qs.total_rows
	FROM 
		SYS.DM_EXEC_QUERY_STATS QS
		CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
		CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-31,GETDATE())		--KASLEME NA DOTAZY, KTERE UZ 31 DNI NIKDO NEPUSTIL
	ORDER BY TOTAL_WORKER_TIME DESC




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			POTOM ULOZENE PROCEDURY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT TOP 50
		QS.DATABASE_ID 
		,QS.OBJECT_ID
		, OBJECT_NAME(QS.OBJECT_ID, QS.DATABASE_ID) AS ObjectName
		, QS.TYPE
		, QS.EXECUTION_COUNT
		, QS.TOTAL_WORKER_TIME
		, QP.QUERY_PLAN
		, QT.TEXT
		, QS.TYPE_DESC
		, QS.SQL_HANDLE
		, QS.PLAN_HANDLE
		, QS.CACHED_TIME
		, QS.LAST_EXECUTION_TIME
		, QS.LAST_WORKER_TIME
		, QS.MIN_WORKER_TIME
		, QS.MAX_WORKER_TIME
	FROM 
	(
		SELECT * FROM SYS.DM_EXEC_PROCEDURE_STATS
		UNION ALL
		SELECT * FROM SYS.DM_EXEC_TRIGGER_STATS
	) AS QS
	LEFT JOIN SYS.SYSOBJECTS SO ON QS.OBJECT_ID = SO.ID
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE())		--KASLEME NA PROCEDURY, KTERE UZ 14 DNI NIKDO NEPUSTIL
	ORDER BY TOTAL_WORKER_TIME DESC




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			PARALELNI DOTAZY
----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Zpusob 1 s exekucnim planem

	SELECT
		p.dbid,
		p.objectid,
		p.query_plan,
		q.encrypted,
		q.TEXT,
		cp.usecounts,
		cp.size_in_bytes,
		cp.plan_handle
	FROM sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS p
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS q
	WHERE cp.cacheobjtype = 'Compiled Plan' AND p.query_plan.value('declare namespace
	p="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; max(//p:RelOp/@Parallel)', 'float') > 0


-- Zpusob 2 bez exekucniho planu

	SELECT
		qs.sql_handle,
		qs.statement_start_offset,
		qs.statement_end_offset,
		q.dbid,
		q.objectid,
		q.number,
		q.encrypted,
		q.TEXT
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS q
	WHERE qs.total_worker_time > qs.total_elapsed_time




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			PRIKAZY PRO TUNING
----------------------------------------------------------------------------------------------------------------------------------------------------------

	/*
	SET STATISTICS TIME, IO ON
	SET STATISTICS TIME, IO OFF

	OPTION (MAXDOP 3)
	OPTION (RECOMPILE)
	*/