----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--													KONTROLA BLOKOVANYCH/BLOKUJICICH PROCESU															--
--									NA ZAKLADE TETO KONTROLY ZJISTIME, KTERE PROCESY BLOKUJI OSTATNI V CINNOSTI											--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			NEJPRVE SPUSTIT LOGOVANI
--			NECHAT BEZET KLIDNE CELY DEN. LOGOVANI NEZATEZUJE SERVER.
----------------------------------------------------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('MASTER..TEMPBLOCKEDPROCMPE') IS NULL
		SELECT 
		SP.SPID,SP.KPID,SP.BLOCKED,SP.WAITTYPE,SP.WAITTIME,SP.LASTWAITTYPE,SP.WAITRESOURCE/*DBID*/,SP.UID,SP.CPU,SP.PHYSICAL_IO,SP.MEMUSAGE,SP.LOGIN_TIME,SP.LAST_BATCH
		,SP.ECID,SP.OPEN_TRAN,SP.STATUS,SP.SID,SP.HOSTNAME,SP.PROGRAM_NAME,SP.HOSTPROCESS,SP.CMD,SP.NT_DOMAIN,SP.NT_USERNAME,SP.NET_ADDRESS,SP.NET_LIBRARY,SP.LOGINAME
		,SP.CONTEXT_INFO,SP.SQL_HANDLE,SP.STMT_START,SP.STMT_END,SP.REQUEST_ID
		, SUBSTRING(QT.TEXT,0,CASE WHEN LEN(QT.TEXT) <= 5000 THEN LEN(QT.TEXT) ELSE 5000 END) AS ZACATEKSTMT
		, SUBSTRING(QT.TEXT,CASE WHEN SP.STMT_START/2 >= 0 THEN SP.STMT_START/2 + 1 ELSE 0 END, CASE WHEN SP.STMT_END/2 - SP.STMT_START/2 > 1 THEN SP.STMT_END/2 - SP.STMT_START/2 +1+1 ELSE 100000 END) AS AKTUALNIPRIKAZ
		, SE.TRANSACTION_ID, SE.ENLIST_COUNT, SE.IS_BOUND, SE.IS_LOCAL, SE.IS_USER_TRANSACTION, SE.TRANSACTION_DESCRIPTOR
		, SP.DBID, DB_NAME(SP.DBID) AS DBNAME
		, GETDATE() AS TIMEOCCUR 
		, 100.00 AS BufferHitRatio
		INTO MASTER..TEMPBLOCKEDPROCMPE					
		FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
		CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT 
		LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
		WHERE BLOCKED > 0
		OR SPID IN (SELECT BLOCKED FROM SYS.SYSPROCESSES WITH (NOLOCK) WHERE BLOCKED > 0)
	INSERT INTO MASTER..TEMPBLOCKEDPROCMPE
	SELECT 0,0,0,0X0000,0,'', '', 0,0,0,0, GETDATE(), GETDATE(),0,0,'', 0X0100, '', '', 0,'','','','','','',0X0100,0X0100,0,0,0,'---START LOGOVANI ---','---START LOGOVANI ---',0,0,0,0,0,0X0000,0,'',GETDATE(), 100.0
	WHILE 1 = 1
	BEGIN
		IF (SELECT COUNT(1) FROM MASTER..TEMPBLOCKEDPROCMPE)>10000 BREAK		--OMEZENI, ABY TABULKA NEBYLA MOC VELKA. 10K RADKU ZHRUBA ODPOVIDA 100MB
		INSERT INTO MASTER..TEMPBLOCKEDPROCMPE
		SELECT 
		SP.SPID,SP.KPID,SP.BLOCKED,SP.WAITTYPE,SP.WAITTIME,SP.LASTWAITTYPE,SP.WAITRESOURCE/*DBID*/,SP.UID,SP.CPU,SP.PHYSICAL_IO,SP.MEMUSAGE,SP.LOGIN_TIME,SP.LAST_BATCH
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
		WHERE counter_name = 'Buffer cache hit ratio base' AND OBJECT_NAME LIKE '%:Buffer Manager%') b ON  a.OBJECT_NAME = b.OBJECT_NAME
		WHERE a.counter_name = 'Buffer cache hit ratio' AND a.OBJECT_NAME LIKE '%:Buffer Manager%'
		) AS BufferHitRatio
		--INTO TEMPBLOCKEDPROCJKO					
		FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
		CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT ------------------------------------------------------------------------ POKUD CHCI "PRAZDNE RADKY", TAK NAHRADIT "CROSS APPLY" ZA "OUTER APPLY" 
		LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
		WHERE BLOCKED > 0
		OR SPID IN (SELECT BLOCKED FROM SYS.SYSPROCESSES WITH (NOLOCK) WHERE BLOCKED > 0)
		PRINT 'AKTUALNI CAS: ' + CONVERT(VARCHAR(50),GETDATE(),120) + ' , ULOZENO ZAZNAMU: ' + CONVERT(VARCHAR(50),@@ROWCOUNT)
		WAITFOR DELAY '00:00:05'
	END




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			ULOZIT INFORMACI O KONCI LOGOVANI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	------------------------ !!! SPUSTIT MANUALNE PO ZASTAVENI LOGOVANI !!! ----- AT JE V LOGU INFORMACE, KDY SE PRESTALO ZAZNAMENAVAT !!!  ------------------------------------------------
	INSERT INTO MASTER..TEMPBLOCKEDPROCMPE
	SELECT 0,0,0,0X0000,0,'', '', 0,0,0,0, GETDATE(), GETDATE(),0,0,'', 0X0100, '', '', 0,'','','','','','',0X0100,0X0100,0,0,0,'---KONEC LOGOVANI ---','---KONEC LOGOVANI ---',0,0,0,0,0,0X0000,0,'',GETDATE(), 100.0
	------------------------ !!! SPUSTIT MANUALNE PO ZASTAVENI LOGOVANI !!! ----- AT JE V LOGU INFORMACE, KDY SE PRESTALO ZAZNAMENAVAT !!!  ------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			KONTROLA VYSLEDKU - ZDE JE VIDET, KTERE PROCESY JSOU BLOKUJICI A KTERE BLOKOVANE
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT DB_NAME(DBID), TIMEOCCUR, SPID, BLOCKED, DBNAME, AKTUALNIPRIKAZ, ZACATEKSTMT, OPEN_TRAN, TRANSACTION_ID, STATUS, PROGRAM_NAME, LEN(AKTUALNIPRIKAZ) AS Delka, * 
	FROM MASTER..TEMPBLOCKEDPROCMPE 
	WHERE 1 = 1
	AND TIMEOCCUR > CONVERT(DATE,DATEADD(DAY,0,GETDATE()))
	AND (BLOCKED = 0 OR SPID = BLOCKED)
	ORDER BY 2 , 4




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			KONTROLA VYSLEDKU - CASTI KODU, KTERE NEJCASTEJI ZPUSOBUJI BLOKACI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT DB_NAME(DBID), AKTUALNIPRIKAZ, ZACATEKSTMT, PROGRAM_NAME, COUNT(1) CNT, LEN(AKTUALNIPRIKAZ) AS Delka
	FROM MASTER..TEMPBLOCKEDPROCMPE 
	WHERE 1=1
	AND (BLOCKED = 0 OR SPID = BLOCKED)
	GROUP BY DB_NAME(DBID), AKTUALNIPRIKAZ, ZACATEKSTMT, PROGRAM_NAME
	ORDER BY CNT DESC, AKTUALNIPRIKAZ

