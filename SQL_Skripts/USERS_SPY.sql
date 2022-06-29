----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																																						--
--																USERS SPY/TRACKING																		--
--													WATCH USERS AND THEIR ACTIVITY ON SQL SERVER														--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--	1. SELECT CONNECTED USERS AND THEIR NUMBER OF CONNECTIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
		DB_NAME(dbid) as DBName 
		,COUNT(dbid) as NumberOfConnections
		,loginame as LoginName
	--SELECT *
	FROM
		sys.sysprocesses
	WHERE 
		dbid > 0
	GROUP BY 
		dbid, loginame




----------------------------------------------------------------------------------------------------------------------------------------------------------
--	2. FIND SQL COMMAND VIA SPID
----------------------------------------------------------------------------------------------------------------------------------------------------------

-- need to fill particular number instead of "spid" in command
	DBCC INPUTBUFFER(spid)




----------------------------------------------------------------------------------------------------------------------------------------------------------
--	3. SHOW ALL OPENED TRANSACTIONS AND THEIR SQL TEXT
----------------------------------------------------------------------------------------------------------------------------------------------------------
		
	SELECT
		GETDATE() as ACTUAL_DATE_TIME
		,DATEDIFF(SECOND, transaction_begin_time, GETDATE()) AS RUNNING_SECONDS
		,st.session_id AS SPID
		,txt.text AS SQL_COMMAND
		,at.transaction_begin_time AS TRANSACTION_BEGIN_TIME
		,sess.login_name AS LOGIN_NAME
		--,*	-- if we want see everything, uncomment it
	FROM
		sys.dm_tran_active_transactions at
		INNER JOIN sys.dm_tran_session_transactions st ON st.transaction_id = at.transaction_id
		LEFT OUTER JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
		LEFT OUTER JOIN sys.dm_exec_connections conn ON conn.session_id = sess.session_id
		OUTER APPLY sys.dm_exec_sql_text(conn.most_recent_sql_handle)  AS txt
	ORDER BY
		RUNNING_SECONDS DESC;
