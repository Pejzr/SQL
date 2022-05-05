

/*
pridat ZALOHOVANI
pridat KAZDODENNI CHECKDB
Posledni spusteni a beh akci - pouzit pro optimalizaci


Brent Ozar
How to Measure Your SQL Server

Pertmon - SQLServer: SQL Statistics - Batch request / sec


Wait Time Ratio
hours of wait time per hour

wait second per per second

*/



--SELECT ZJISTI PRACOVNI DATABAZI. VYCHAZIME Z PREDPOKLADU, ZE V PRACOVNI DATABAZI JE PRIHLASENO PODSTATNE VICE UZIVATELU (PROCESU), NEZ V OSTATNICH DATABAZICH

	SELECT DB_NAME(DBID) DB, COUNT(1) CNT FROM SYS.SYSPROCESSES WHERE SPID > 50 AND DBID > 4
	GROUP BY DB_NAME(DBID)
	ORDER BY CNT DESC

USE XXX
GO

IF OBJECT_ID('TmpxExterniIndexy') IS NULL
    CREATE TABLE TmpxExterniIndexy (name NVARCHAR(128) PRIMARY KEY, DatumZapisu DATETIME DEFAULT GETDATE())
INSERT INTO TmpxExterniIndexy (name)
SELECT name FROM SYS.indexes WHERE NAME LIKE 'IXe%' AND NAME NOT IN (SELECT name FROM TmpxExterniIndexy)


--replace "XXX" za databazi

/*
1.
KONTROLA BLOKOVANYCH/BLOKUJICICH PROCESU
2.
KONTROLA STATISTIK
3.
KONTROLA NEJNAROCNEJSICH DOTAZU / PROCEDUR
4.
KONTROLA WAIT STAVU
5.
KONTROLA PARAMETRU SERVERU / DATABAZE
6.
KONTROLA TRACE SOUBORU - OPET SE MRKNOUT
7.
VYTVORENI JOBU, KTERY BUDE ZALOHOVAT SYSTEMOVE VIEW: SYS.DM_DB_INDEX_USAGE_STATS
8.
KONTROLA ZDA EXISTUJE NEJAKA MAINTENANCE RUTINA
*/


----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--									SELECTY, KTERE ZJISTI AKTUALNI ZDRAVI SQL SERVERU A NAVRHNOU LECBU													--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------

--Kontrola napajeni

SELECT 'Jeste zkontrolovat Power schema'


--Mód napájení serveru
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




--Kontrola zda je nainstalovany posledni SP

SELECT @@VERSION

--Kontrola CMTP levelu

SELECT * FROM SYS.DATABASES 


SELECT name, value FROM sys.database_scoped_configurations  

SELECT name, value  
    FROM tempdb.sys.database_scoped_configurations  

SELECT name, value  
    FROM model.sys.database_scoped_configurations  

/*
USE Helios001
 ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  
 USE tempdb ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  
 USE model ALTER DATABASE     SCOPED CONFIGURATION           SET LEGACY_CARDINALITY_ESTIMATION = ON;  
*/

SELECT 'Nezapomen na: ALTER DATABASE Helios001 SET TARGET_RECOVERY_TIME = 0 SECONDS;'
SELECT 'Nezapomen na: ALTER DATABASE model SET TARGET_RECOVERY_TIME = 0 SECONDS;'
SELECT 'Nezapomen na: ALTER DATABASE tempdb SET TARGET_RECOVERY_TIME = 0 SECONDS;'

/*

Nezapomenout na dalsi moznosti optimalizace

    - Omezene nacitani dat
    - spinave cteni
    - partitioning
    - data compression

*/

SELECT PovolenNOLOCK, * FROM TabFiltr



----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- využití jáder (zda jsou online - souvisí s licencovanim)

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
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				1.
--				KONTROLA BLOKOVANYCH/BLOKUJICICH PROCESU
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, KTERE PROCESY BLOKUJI OSTATNI V CINNOSTI
--


--				1.A NEJPRVE SPUSTIT LOGOVANI
--				NECHAT BEZET KLIDNE CELY DEN. LOGOVANI NEZATEZUJE SERVER.

IF OBJECT_ID('TEMPDB..TEMPBLOCKEDPROCJKO') IS NULL
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
	INTO TEMPDB..TEMPBLOCKEDPROCJKO					
	FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT 
	LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
	WHERE BLOCKED > 0
	OR SPID IN (SELECT BLOCKED FROM SYS.SYSPROCESSES WITH (NOLOCK) WHERE BLOCKED > 0)
INSERT INTO TEMPDB..TEMPBLOCKEDPROCJKO
SELECT 0,0,0,0X0000,0,'', '', 0,0,0,0, GETDATE(), GETDATE(),0,0,'', 0X0100, '', '', 0,'','','','','','',0X0100,0X0100,0,0,0,'---START LOGOVANI ---','---START LOGOVANI ---',0,0,0,0,0,0X0000,0,'',GETDATE(), 100.0
WHILE 1 = 1
BEGIN
	IF (SELECT COUNT(1) FROM TEMPDB..TEMPBLOCKEDPROCJKO)>10000 BREAK		--OMEZENI, ABY TABULKA NEBYLA MOC VELKA. 10K RADKU ZHRUBA ODPOVIDA 100MB
	INSERT INTO TEMPDB..TEMPBLOCKEDPROCJKO
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


----------------------------------------------------------------

--				1.B ULOZIT INFORMACI O KONCI LOGOVANI

------------------------ !!! SPUSTIT MANUALNE PO ZASTAVENI LOGOVANI !!! ----- AT JE V LOGU INFORMACE, KDY SE PRESTALO ZAZNAMENAVAT !!!  ------------------------------------------------
INSERT INTO TEMPDB..TEMPBLOCKEDPROCJKO
SELECT 0,0,0,0X0000,0,'', '', 0,0,0,0, GETDATE(), GETDATE(),0,0,'', 0X0100, '', '', 0,'','','','','','',0X0100,0X0100,0,0,0,'---KONEC LOGOVANI ---','---KONEC LOGOVANI ---',0,0,0,0,0,0X0000,0,'',GETDATE(), 100.0
------------------------ !!! SPUSTIT MANUALNE PO ZASTAVENI LOGOVANI !!! ----- AT JE V LOGU INFORMACE, KDY SE PRESTALO ZAZNAMENAVAT !!!  ------------------------------------------------



----------------------------------------------------------------

--				1.C KONTROLA VYSLEDKU - ZDE JE VIDET, KTERE PROCESY JSOU BLOKUJICI A KTERE BLOKOVANE

SELECT DB_NAME(DBID), TIMEOCCUR, SPID, BLOCKED, DBNAME, AKTUALNIPRIKAZ, ZACATEKSTMT, OPEN_TRAN, TRANSACTION_ID, STATUS, PROGRAM_NAME, LEN(AKTUALNIPRIKAZ) AS Delka, * 
FROM TEMPDB..TEMPBLOCKEDPROCJKO 
WHERE 1 = 1
AND TIMEOCCUR > CONVERT(DATE,DATEADD(DAY,0,GETDATE()))
AND (BLOCKED = 0 OR SPID = BLOCKED)
ORDER BY 2 , 4


----------------------------------------------------------------

--				1.D KONTROLA VYSLEDKU - CASTI KODU, KTERE NEJCASTEJI ZPUSOBUJI BLOKACI

SELECT DB_NAME(DBID), AKTUALNIPRIKAZ, ZACATEKSTMT, PROGRAM_NAME, COUNT(1) CNT, LEN(AKTUALNIPRIKAZ) AS Delka
FROM TEMPDB..TEMPBLOCKEDPROCJKO 
WHERE 1=1
AND (BLOCKED = 0 OR SPID = BLOCKED)
GROUP BY DB_NAME(DBID), AKTUALNIPRIKAZ, ZACATEKSTMT, PROGRAM_NAME
ORDER BY CNT DESC, AKTUALNIPRIKAZ


----------------------------------------------------------------

--				1.E PRO PREDANI VYSLEDKU K ANALYZE SPUSTIT:

SELECT * FROM TEMPDB..TEMPBLOCKEDPROCJKO 
--VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT




----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				2.
--				KONTROLA STATISTIK
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, ZDA JSOU STATISTIKY TABULEK A INDEXU AKTUALNI
--
--				OBECNE RECENO - STATISTIKY BY MELY BYT CO NEJAKTUALNEJSI. MINIMALNE STATISTIKY NAD NEJPOUZIVANEJSIMI TABULKEMI (TabPohybyZbozi, TabPohybyZbozi, TabDenik ...)
--				BY NEMELY BYT STARSI NEZ 24HOD.


----------------------------------------------------------------

--				2.A VSECHNY STATISTIKY OD NEJSTARSI
--				

SELECT OBJECT_NAME(OBJECT_ID) AS [OBJECTNAME] ,[NAME] AS [STATISTICNAME], STATS_DATE([OBJECT_ID], [STATS_ID]) AS [STATISTICUPDATEDATE], *
FROM SYS.STATS 
WHERE OBJECTPROPERTY(OBJECT_ID, 'ISUSERTABLE') = 1										/*Je to uzivatelska tabulka*/
AND OBJECT_ID IN (SELECT id FROM SYS.sysindexes WHERE indid IN (0,1) AND rowcnt > 0)	/* a ma alespon 1 radek*/
ORDER BY 3 


----------------------------------------------------------------

--				2.B VSECHNY STATISTIKY PRO KONKRETNI TABULKY

SELECT OBJECT_NAME(OBJECT_ID) AS [OBJECTNAME] ,[NAME] AS [STATISTICNAME], STATS_DATE([OBJECT_ID], [STATS_ID]) AS [STATISTICUPDATEDATE], *
FROM SYS.STATS WHERE OBJECT_NAME(OBJECT_ID) IN (', ', ', ')
ORDER BY 3 

--				2.B VSECHNY STATISTIKY VCETNE VELIKOSTI SAMPLE

SELECT 
OBJECT_NAME(stat.OBJECT_ID) AS [OBJECTNAME] ,[NAME] AS [STATISTICNAME], STATS_DATE(stat.OBJECT_ID, stat.STATS_ID) AS [STATISTICUPDATEDATE]
, last_updated, rows, rows_sampled, CONVERT(NUMERIC(3,0),rows_sampled*100/rows) AS Sample_Percent
FROM sys.stats AS stat   
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
ORDER by 3



----------------------------------------------------------------

--				2.C NEJSTARSI A NEJNOVEJSI STATISTIKY PRO KONKRETNI TABULKY

SELECT OBJECT_NAME(OBJECT_ID) AS [OBJECTNAME] 
,MIN(STATS_DATE([OBJECT_ID], [STATS_ID])) AS [NEJSTARSISTATISTIKA]
, DATEDIFF(DAY, MIN(STATS_DATE([OBJECT_ID], [STATS_ID])), GETDATE()) AS [POCETDNI1]
, MAX(STATS_DATE([OBJECT_ID], [STATS_ID])) AS [NEJNOVEJSISTATISTIKA]
, DATEDIFF(DAY, MAX(STATS_DATE([OBJECT_ID], [STATS_ID])), GETDATE()) AS [POCETDNI2]
, COUNT(1) AS [POCETSTATISTIK]
, CASE WHEN DATEDIFF(DAY, MIN(STATS_DATE([OBJECT_ID], [STATS_ID])), GETDATE()) > 1 THEN 'PROBLEM - STARA STATISTIKA' ELSE 'OK' END AS INFO
FROM SYS.STATS WHERE OBJECT_NAME(OBJECT_ID) IN ('TabPohybyZbozi', 'TabDokladyZbozi', 'TabDenik', '')
GROUP BY OBJECT_NAME(OBJECT_ID)


----------------------------------------------------------------

--				2.D PRO PREDANI VYSLEDKU K ANALYZE SPUSTIT:
SELECT OBJECT_NAME(OBJECT_ID) AS [OBJECTNAME] ,[NAME] AS [STATISTICNAME], STATS_DATE([OBJECT_ID], [STATS_ID]) AS [STATISTICUPDATEDATE], *
FROM SYS.STATS 
WHERE OBJECTPROPERTY(OBJECT_ID, 'ISUSERTABLE') = 1										/*Je to uzivatelska tabulka*/
AND OBJECT_ID IN (SELECT id FROM SYS.sysindexes WHERE indid IN (0,1) AND rowcnt > 0)	/* a ma alespon 1 radek*/
--VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT




----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				3.
--				KONTROLA NEJNAROCNEJSICH DOTAZU / PROCEDUR
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, KTERE DOTAZY/PROCEDURY SPOTREBOVAVAJI NEJVICE CPU CASU A JEJICH EXEKUCNI PLAN.
--				VYSLEDKY JE NUTNE BRAT S REZERVOU, PROTOZE "ZDROJOVA DATA" SE KUMULUJI OD KDOVIKDY
--				PO TETO KONTROLE JE MOZNE ZKONTROLOVAT STATISTIKY NA PROBLEMOVYCH TABULKACH, POPRIPADE NAVRHNOUT DOPORUCENE INDEXY


----------------------------------------------------------------

--				3.A NEJPRVE DOTAZY

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

----------------------------------------------------------------

--				3.B POTOM ULOZENE PROCEDURY

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


----------------------------------------------------------------

--				3.C UPRAVY
--				OPTIMALIZACI NAROCNYCH DOTAZU/PROCEDUR JE MOZNE REALIZOVAT BUD UPRAVOU KODU, NEBO ZAVEDENIM INDEXU
--				NICMENE PRI ZAVEDENI NOVYCH INDEXU JE TREBA DAT POZOR, ZDA HELIOS JIZ INDEXY NEOBSAHUJE NAD STEJNYMI KLICOVYMI SLOUPCI
--				POKUD EXISTUJE VLASTNI INDEX HELIOSU NAD STEJNYMI KLICOVYMI SLOUPCI, VE STEJNEM PORADI, TAK HELIOS PRI KONTROLE ZAHLASI CHYBU A NEJDE SPUSTIT

--				KONTROLU INDEXU JE MOZNE REALIZOVAT BUD:

EXEC SP_HELPINDEX 		--<< DOPLN TABULKU

--NEBO:

SELECT O.NAME TableName, I.NAME IndexName, C.NAME ColumnName, CASE IC.IS_INCLUDED_COLUMN WHEN 0 THEN '' ELSE 'INCLUDED' END Is_Included, ISNULL(i.filter_definition, '') filter_definition,  IC.* 
FROM SYS.INDEXES I 
JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
JOIN SYS.COLUMNS C ON IC.OBJECT_ID = C.OBJECT_ID AND IC.COLUMN_ID = C.COLUMN_ID
JOIN SYS.OBJECTS O ON I.OBJECT_ID = O.OBJECT_ID
WHERE 1 = 1
	AND O.NAME = ''	--<< DOPLN TABULKU
	AND I.NAME = ''	--<< DOPLN NAZEV INDEXU
ORDER BY O.NAME, I.NAME, INDEX_COLUMN_ID



----------------------------------------------------------------

--				3.D POKUD UZ JE NASAZENY ZALOHUJICI JOB, TAK PRO ANALYZU POUZIT:

SELECT SQLTEXT, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MIN(CREATION_TIME) CREATION_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME, COUNT(1) CNT 
FROM SYS_DM_EXEC_QUERY_STATS_JKO WHERE DBID = DB_ID()
GROUP BY SQLTEXT
ORDER BY TOTAL_WORKER_TIME DESC

SELECT NAME, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MIN(CACHED_TIME) CREATION_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME, COUNT(1) CNT 
FROM SYS_DM_EXEC_PROCEDURE_STATS_JKO WHERE DATABASE_ID = DB_ID()
GROUP BY NAME
ORDER BY TOTAL_WORKER_TIME DESC




----------------------------------------------------------------

--				3.E PRO PREDANI VYSLEDKU K ANALYZE NEJPRVE NASTAVIT:
/*
NASTAVIT:
TOOLS - OPTIONS
	QUERY RESULTS - SQL SERVER - RESULTS TO GRID
MAXIMUM CHARACTERS RETRIEVED
	NONXMLDATA = 65535
	XML DATA   = UNLIMITED

POTVRDIT "OK"
*/

--POTOM SPUSTIT:
SELECT TOP 100 REPLACE(REPLACE(SUBSTRING(CONVERT(NVARCHAR(MAX),QT.TEXT), (QS.STATEMENT_START_OFFSET/2)+1,
((CASE QS.STATEMENT_END_OFFSET WHEN -1 THEN DATALENGTH(QT.TEXT) ELSE QS.STATEMENT_END_OFFSET END - QS.STATEMENT_START_OFFSET)/2)+1) 
, CHAR(13), ' '), CHAR(09), ' ') AS SQLTEXT, QS.EXECUTION_COUNT, QS.TOTAL_WORKER_TIME, QS.LAST_WORKER_TIME,
CONVERT(XML, REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), QP.QUERY_PLAN),CHAR(13), ' '), CHAR(09), ' '))
FROM SYS.DM_EXEC_QUERY_STATS QS
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE())		
ORDER BY TOTAL_WORKER_TIME DESC
--VYSLEDKY ULOZIT DO TEXTAKU - TAB DELIMITED A PREDAT



----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				4.
--				KONTROLA WAIT STAVU
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, NA CO SQL SERVER NEJCASTEJI CEKA
--


----------------------------------------------------------------

--				4.A PRO PREDANI VYSLEDKU K ANALYZE SPUSTIT:


SELECT 
WAIT_TYPE AS [Typ èekání]
, WAIT_TIME_MS/1000/60 AS [Celková doba v minutách]
, WAITING_TASKS_COUNT AS [Poèet èekání]
, WAIT_TIME_MS / WAITING_TASKS_COUNT /1000/60 AS [Prùmìrné èekání]
FROM SYS.DM_OS_WAIT_STATS WHERE WAITING_TASKS_COUNT > 0 ORDER BY 2 DESC
--VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT


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
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				5.
--				KONTROLA PARAMETRU SERVERU / DATABAZE
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, ZDA NEJSOU NEKTERE VLASTNOSTI SQL SERVERU NASTAVENE NESPRAVNE
--

----------------------------------------------------------------

--				5.A PARAMETRY SERVERU - NEJPRVE POUZE VYBRANE PARAMETRY

	SELECT 
	NAME
	, VALUE_IN_USE
	, DESCRIPTION
	, CASE 
		WHEN NAME = 'cost threshold for parallelism' AND VALUE_IN_USE = '20' THEN 'OK'	--DOPORUCENA HODNOTA 20
		WHEN NAME = 'max degree of parallelism' AND VALUE_IN_USE = '8' THEN 'OK'		--DOPORUCENA HODNOTA 4, NEBO 8
		WHEN NAME = 'optimize for ad hoc workloads' AND VALUE_IN_USE = '1' THEN 'OK'	--DOPORUCENA HODNOTA 1
		WHEN NAME = 'blocked process threshold (s)' AND VALUE_IN_USE = '0' THEN 'OK'	--DOPORUCENA HODNOTA 0
		ELSE 'Tezko rict ...'
		END AS Info
	 FROM SYS.configurations
	 WHERE configuration_id IN (1538, 1539, 1569, 1581)	


----------------------------------------------------------------

--				5.B PARAMETRY SERVERU - POTOM VSECHNY PARAMETRY

	EXEC sp_configure


----------------------------------------------------------------

--				5.C PARAMETRY DATABAZE - POUZE VYBRANE PARAMETRY
	
	SELECT 
	 CASE WHEN collation_name <> 'Czech_CI_AS'		THEN 'PROBLEM: ' + collation_name ELSE collation_name																	END collation_name
	,CASE WHEN is_auto_shrink_on <> 0				THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_shrink_on) ELSE CONVERT(NVARCHAR(10), is_auto_shrink_on)				END is_auto_shrink_on
	,CASE WHEN recovery_model <> 3					THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), recovery_model) ELSE CONVERT(NVARCHAR(10), recovery_model)					END recovery_model
	,CASE WHEN recovery_model_desc <> 'SIMPLE'		THEN 'PROBLEM: ' +  recovery_model_desc ELSE recovery_model_desc														END recovery_model_desc
	,CASE WHEN is_auto_create_stats_on <> 1			THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_create_stats_on) ELSE CONVERT(NVARCHAR(10), is_auto_create_stats_on)	END is_auto_create_stats_on
	,CASE WHEN is_auto_update_stats_on <> 1			THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_update_stats_on) ELSE CONVERT(NVARCHAR(10), is_auto_update_stats_on)	END is_auto_update_stats_on
	,CASE WHEN is_auto_update_stats_async_on <> 0	THEN 'PROBLEM: ' +  CONVERT(NVARCHAR(10), is_auto_update_stats_async_on) ELSE CONVERT(NVARCHAR(10), is_auto_update_stats_async_on) END is_auto_update_stats_async_on
	FROM SYS.DATABASES WHERE database_id = DB_ID()


----------------------------------------------------------------

--				5.D PARAMETRY DATABAZOVYCH SOUBORU - NEJPRVE POUZE VYBRANE PARAMETRY

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



----------------------------------------------------------------

--				5.E PRO PREDANI VYSLEDKU K SPUSTIT 5A, 5B, 5C, 5D, VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT





----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				6.
--				KONTROLA TRACE SOUBORU - OPET SE MRKNOUT


----------------------------------------------------------------

--				6.A NEJPRVE KONTROLA VSECH ZAZNAMU BEZ FILTRACE

DECLARE @FILENAME VARCHAR(MAX) 
SELECT @FILENAME = CAST(VALUE AS VARCHAR(MAX)) 
	FROM FN_TRACE_GETINFO(DEFAULT) 
	WHERE PROPERTY = 2 
	AND VALUE IS NOT  NULL
PRINT @FILENAME 
SELECT DatabaseName, LoginName, StartTime, ApplicationName, name, *
	FROM [FN_TRACE_GETTABLE](@FILENAME, DEFAULT) GT 
	JOIN SYS.TRACE_EVENTS TE ON GT.EVENTCLASS = TE.TRACE_EVENT_ID 
	ORDER BY 3 DESC

GO


----------------------------------------------------------------

--				6.B POTOM PODLE CETNOSTI VYSKYTU, BEZ NEPOTREBNYCH ZAZNAMU

DECLARE @FILENAME VARCHAR(MAX) 
SELECT @FILENAME = CAST(VALUE AS VARCHAR(MAX)) 
	FROM FN_TRACE_GETINFO(DEFAULT) 
	WHERE PROPERTY = 2 
	AND VALUE IS NOT  NULL
PRINT @FILENAME 
SELECT CONVERT(NVARCHAR(MAX),TextData), COUNT(1) CNT, MIN(StartTime) AS PrvniUdalost, MAX(StartTime) AS PosledniUdalost
	FROM [FN_TRACE_GETTABLE](@FILENAME, DEFAULT) GT 
	JOIN SYS.TRACE_EVENTS TE ON GT.EVENTCLASS = TE.TRACE_EVENT_ID 
	WHERE CONVERT(NVARCHAR(MAX),TextData) NOT LIKE '%NO STATS:(\[tempdb%' ESCAPE '\'
	AND CONVERT(NVARCHAR(MAX),TextData) NOT LIKE '%Login failed for user%'
	AND CONVERT(NVARCHAR(MAX),TextData) NOT LIKE '%BACKUP DATABASE%'
	AND CONVERT(NVARCHAR(MAX),TextData) IS NOT NULL
	GROUP BY CONVERT(NVARCHAR(MAX),TextData)
	ORDER BY CNT DESC


----------------------------------------------------------------

--				6.C PRO PREDANI VYSLEDKU K SPUSTIT 6B, VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT






----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				7.
--				VYTVORENI JOBU, KTERY BUDE ZALOHOVAT SYSTEMOVE VIEW: SYS.DM_DB_INDEX_USAGE_STATS
--				ACKOLIM MS TVRDI, ZE STATISTIKY V TOMTO VIEW SE MAZOU PRI RESTARTU SERVERU, NEBO PRO ODPOJENI DB, TAK REALNE SE ZAZNAMY NULUJI I PRI REBUILDU INDEXU
--				TOTO SE DEJE JAK V MSSQL 2012, TAK I V MSSQL 2014.
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, JESTLI NEEXISTUJI INDEXY, KTERYCH BY BYLO VHODNE SE ZBAVIT (DISABLOVAT)


----------------------------------------------------------------

--				7.A NEJPRVE VYTVORENI JOBU 


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

--				7.B ANALYZA UDAJU ZAZNAMENANYCH JOBEM + NAVRH INDEXU PRO DISABLOVANI
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

--				7.C KONTROLA, ZDA JE MOZNE INDEXY OPRAVDU DISABLOVAT
--				JELIKOZ HELIOS SI HLIDA VLASTNI INDEXY, NENI MOZNE INDEXY DROPNOUT, PROTOZE PRI NASLEDUJICI KONTROLE BY BYLY ZNOVU VYTVORENY
--				JE TEDY POUZE MOZNE INDEXY DISABLOVAT
--				NICMENE SE MUZE STAT, ZE INDEX JE POUZITY PRIMO V ZAPSANEM SELECTU JAKO HINT, PAK BY PO DISABLOVANI HLASIL HELIOS CHYBU
--				PROTO JE NUTNE ZKONTROLOVAT ZDA SE NAZEV INDEXU NEVYSKYTUJE VE ZDROJOVYCH KODECH !!!


----------------------------------------------------------------

--				7.D PRO PREDANI VYSLEDKU K ANALYZE SPUSTIT (NEJDRIVE 1 TYDEN PO SPUSTENI JOBU):


SELECT * FROM SYS_DM_DB_INDEX_USAGE_STATS_JKO jko
JOIN sys.indexes i ON jko.IndexName = i.name
--VYSLEDKY ULOZIT DO TEXTAKU/EXCELU A PREDAT





----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------



--				8.
--				KONTROLA ZDA EXISTUJE NEJAKA MAINTENANCE RUTINA
--				DEFRAGMENTACE INDEXU (REBUILD, REORGANIZE), AKTUALIZACE STATISTIK PRO VSECHNY TABULKY
--				POKUD NE, TAK VYTVORIT
--				IDEALNE UDELAT JAKO JOB


----------------------------------------------------------------

--				8.A JEDNORAZOVA UDRZBA - DEFRAGMETACE INDEXU

/*DEFRAGMENTACE INDEXU*/
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


----------------------------------------------------------------

--				8.B JEDNORAZOVA UDRZBA - AKTUALIZACE STATISTIK

/*AKTUALIZACE STATISTIK*/
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


 


----------------------------------------------------------------

--				8.C VYTVORENI JOBU


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




--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------
--------------------------------



----------------------------------------------------------------

--				X.X KONTROLA VYUZITI INDEXU


SELECT SUM(CONVERT(BIGINT,VYUZITI)) VYUZITI, SUM(CONVERT(BIGINT,AKTUALIZACE)) AKTUALIZACE, COUNT(1) CNT, TABLENAME, INDEXNAME, MIN(DATESAVE) PRVNIULOZENI, MAX(DATESAVE) POSLEDNIULOZENI, IS_DISABLED
, CASE WHEN SUM(CONVERT(BIGINT,VYUZITI)) * 10 < SUM(CONVERT(BIGINT,AKTUALIZACE)) THEN 'ALTER INDEX ' + IndexName + ' ON ' + TableName + ' DISABLE'
ELSE '' END AS Zakazat
FROM SYS_DM_DB_INDEX_USAGE_STATS_JKO JKO
JOIN SYS.OBJECTS O ON JKO.TABLENAME = O.NAME
JOIN SYS.SCHEMAS SCH ON O.SCHEMA_ID = SCH.SCHEMA_ID
JOIN SYS.INDEXES I ON OBJECT_ID(SCH.name + '.' + JKO.TABLENAME) = I.OBJECT_ID AND JKO.INDEXNAME = I.NAME
--WHERE INDEXNAME LIKE '%IXE%'
GROUP BY TABLENAME, INDEXNAME, IS_DISABLED
ORDER BY 1, 2 DESC




----------------------------------------------------------------

--				X.X KONTROLA NEJNAROCNEJSICH DOTAZU

SELECT SQLTEXT, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME
, CONVERT(DATE, MIN(CREATION_TIME)) CREATION_TIME, CONVERT(DATE, MAX(LAST_EXECUTION_TIME)) LAST_EXECUTION_TIME
, DATEDIFF(DAY, MIN(CREATION_TIME), MAX(LAST_EXECUTION_TIME)) USEDAYS
FROM
	(
	SELECT SQLTEXT, CREATION_TIME, MAX(EXECUTION_COUNT) EXECUTION_COUNT, MAX(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME
	FROM SYS_DM_EXEC_QUERY_STATS_JKO
	GROUP BY SQLTEXT, CREATION_TIME
	) x
GROUP BY SQLTEXT
ORDER BY TOTAL_WORKER_TIME DESC


----------------------------------------------------------------

--				X.X KONTROLA NEJNAROCNEJSICH PROCEDUR

SELECT GR2.*, PL.QUERY_PLAN
FROM 
	(
	SELECT OBJECT_ID, NAME, MIN(CACHED_TIME) CACHED_TIME, SUM(EXECUTION_COUNT) EXECUTION_COUNT, SUM(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME, MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME
	FROM
		(
		SELECT OBJECT_ID, NAME, CACHED_TIME, MAX(EXECUTION_COUNT) EXECUTION_COUNT, MAX(TOTAL_WORKER_TIME) TOTAL_WORKER_TIME,  MAX(LAST_EXECUTION_TIME) LAST_EXECUTION_TIME
		FROM SYS_DM_EXEC_PROCEDURE_STATS_JKO GROUP BY OBJECT_ID, NAME, CACHED_TIME
		) GR
	GROUP BY OBJECT_ID, NAME
	) GR2
LEFT JOIN 
	(
	SELECT OBJECT_ID, QUERY_PLAN, INSERTDATE, ROW_NUMBER() OVER (PARTITION BY OBJECT_ID ORDER BY INSERTDATE DESC) ROWNUM
	FROM SYS_DM_EXEC_PROCEDURE_STATS_JKO 
	WHERE QUERY_PLAN IS NOT NULL
	) PL 
ON GR2.OBJECT_ID = PL.OBJECT_ID AND PL.ROWNUM = 1
--WHERE NAME LIKE 'HP%' OR NAME LIKE 'PREPOCTI%'		--Pouze procedury Heliosu
ORDER BY TOTAL_WORKER_TIME DESC



----------------------------------------------------------------

--				X.X KONTROLA PODLE IO ... V PRIPADE, ZE VE VELKE CTENI/ZAPIS V ACTIVITY MONITORU

	SELECT TOP 10
	SP.physical_io
	, SP.last_batch
	, SUBSTRING(QT.TEXT,CASE WHEN SP.STMT_START/2 >= 0 THEN SP.STMT_START/2 + 1 ELSE 0 END, CASE WHEN SP.STMT_END/2 - SP.STMT_START/2 > 1 THEN SP.STMT_END/2 - SP.STMT_START/2 ELSE 100000 END) AS AKTUALNIPRIKAZ
	, SUBSTRING(QT.TEXT,0,CASE WHEN LEN(QT.TEXT) <= 5000 THEN LEN(QT.TEXT) ELSE 5000 END) AS ZACATEKSTMT
	, SP.DBID, DB_NAME(SP.DBID) AS DBNAME
	, 'DBCC INPUTBUFFER(' + CONVERT(NVARCHAR(10),SPID) + ')' AS CMD
	FROM SYS.SYSPROCESSES SP WITH (NOLOCK)		
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT ------------------------------------------------------------------------ POKUD CHCI "PRAZDNE RADKY", TAK NAHRADIT "CROSS APPLY" ZA "OUTER APPLY" 
	WHERE SP.spid > 50
	ORDER BY 1 DESC






-----------------------


SELECT 
SUBSTRING(QT.TEXT, (QS.STATEMENT_START_OFFSET/2)+1,
((CASE QS.STATEMENT_END_OFFSET
WHEN -1 THEN DATALENGTH(QT.TEXT)
ELSE QS.STATEMENT_END_OFFSET
END - QS.STATEMENT_START_OFFSET)/2)+1) AS SQLTEXT
,SUM(QS.total_physical_reads) AS sum_total_physical_reads
,SUM(QS.execution_count) AS sum_execution_count
FROM 
SYS.DM_EXEC_QUERY_STATS QS
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-1,GETDATE())		--KASLEME NA DOTAZY, KTERE UZ 31 DNI NIKDO NEPUSTIL
--and QT.text like 'SELECT TOP 1500%'
and QS.total_physical_reads > 0
group by SUBSTRING(QT.TEXT, (QS.STATEMENT_START_OFFSET/2)+1,
((CASE QS.STATEMENT_END_OFFSET
WHEN -1 THEN DATALENGTH(QT.TEXT)
ELSE QS.STATEMENT_END_OFFSET
END - QS.STATEMENT_START_OFFSET)/2)+1)
order by 2 desc





----------------------------------------------------------------------------------------------------------------------------------------------------------


--				X.
--				POROVNANI DOBY BEHU PROCEDUR
--
--				TENTO SELECT POROVNA DOBY BEHU PROCEDUR PRED ZACATKEM UPRAV S AKTUALNIMI
--


select name, kdy, SUM(TOTAL_WORKER_TIME) / SUM(EXECUTION_COUNT ) as Prumernadoba, SUM(TOTAL_WORKER_TIME) CelkovyCacCPU, SUM(EXECUTION_COUNT ) CelkemExecutionCount
FROM
(
select NAME, (select convert(date, MIN(InsertDate)) FROM SYS_DM_EXEC_QUERY_STATS_JKO) AS Kdy, TOTAL_WORKER_TIME/EXECUTION_COUNT AS PrumernaDoba , TOTAL_WORKER_TIME, EXECUTION_COUNT 
--,  * 
from SYS_DM_EXEC_PROCEDURE_STATS_JKO QS
where convert(date, INSERTDATE) = (select convert(date, MIN(InsertDate)) FROM SYS_DM_EXEC_QUERY_STATS_JKO)
UNION ALL
--select 'PoUpravach' AS Kdy, TOTAL_WORKER_TIME/EXECUTION_COUNT AS PrumernaDoba,  * from SYS_DM_EXEC_PROCEDURE_STATS_JKO QS
--where convert(date, INSERTDATE) = '2014-12-07'
SELECT SO.name, GETDATE() AS Kdy, TOTAL_WORKER_TIME/EXECUTION_COUNT AS PrumernaDoba , TOTAL_WORKER_TIME, EXECUTION_COUNT 
--, QS.DATABASE_ID, QS.OBJECT_ID, SO.NAME, QS.TYPE, QS.EXECUTION_COUNT, QS.TOTAL_WORKER_TIME, QP.QUERY_PLAN, QT.TEXT, QS.CACHED_TIME, QS.LAST_EXECUTION_TIME, GETDATE() INSERTDATE
	FROM SYS.DM_EXEC_PROCEDURE_STATS QS
	LEFT JOIN SYS.SYSOBJECTS SO ON QS.OBJECT_ID = SO.ID
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QS.SQL_HANDLE) QT
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(QS.PLAN_HANDLE) QP
	WHERE LAST_EXECUTION_TIME > DATEADD(DAY,-14,GETDATE()) 
	AND QT.TEXT NOT LIKE '%SYS_DM_EXEC_PROCEDURE_STATS_JKO%'
	AND So.name in
		(select name from SYS_DM_EXEC_PROCEDURE_STATS_JKO QS where convert(date, INSERTDATE) = (select convert(date, MIN(InsertDate)) FROM SYS_DM_EXEC_QUERY_STATS_JKO))
) x
where NAME is not NULL
group by NAME, Kdy
order by name, Kdy 







----------------------------------------------------------------------------------------------------------------------------------------------------------


--				X.
--				KONTROLA DUPLICITNICH INDEXU
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, ZDA NEBYLY VYTVORENY INDEXY S DUPLICITNIMI KLICI
--

--				X.
--				KONTROLA DUPLICITNICH INDEXU
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, ZDA NEBYLY VYTVORENY INDEXY S DUPLICITNIMI KLICI
--

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









DBCC FREEPROCCACHE()







----------------------------------------------------------------------------------------------------------------------------------------------------------


--				.
--				ROZKOPIROVANI INDEXU ixE DO OSTATNICH DATABAZI
--
--

SET NOCOUNT ON

IF OBJECT_ID('TEMPDB..#INDEXY ') IS NOT NULL DROP TABLE #INDEXY 
CREATE TABLE #INDEXY (TABLENAME NVARCHAR(128), INDEXNAME NVARCHAR(128), SLOUPCE NVARCHAR(1000), INCSLOUPCE NVARCHAR(1000), filter_definition NVARCHAR(MAX))

DECLARE @TABULKA NVARCHAR(128), @INDEXNAME NVARCHAR(128), @OBJECT_ID INT, @INDEX_ID INT, @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX), @filter_definition NVARCHAR(MAX)

DECLARE CUR CURSOR LOCAL FOR
SELECT OBJECT_NAME(OBJECT_ID), OBJECT_ID, NAME, INDEX_ID, filter_definition 
	FROM SYS.INDEXES I

OPEN CUR
WHILE 1 = 1
BEGIN
	FETCH CUR INTO @TABULKA, @OBJECT_ID, @INDEXNAME ,@INDEX_ID, @filter_definition 
	IF @@FETCH_STATUS <> 0 BREAK
	SET @SLOUPCE = ''
	SET @INCSLOUPCE = ''

	SELECT @SLOUPCE =  @SLOUPCE + SC.NAME 
	+ CASE WHEN IC.is_descending_key = 1 THEN ' DESC ' ELSE '' END
	+ ', ' --CONVERT(NVARCHAR(10), COLUMN_ID) + '_' 
	FROM SYS.INDEXES I
		JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
		JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
	WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
	AND IS_INCLUDED_COLUMN = 0
	AND I.name LIKE 'IXe%'
	ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID


	SELECT @INCSLOUPCE =  @INCSLOUPCE + SC.NAME + ', ' --CONVERT(NVARCHAR(10), COLUMN_ID) + '_' 
	FROM SYS.INDEXES I
		JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
		JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
	WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
	AND IS_INCLUDED_COLUMN = 1
	AND I.name LIKE 'IXe%'
	ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID
	IF LEN(@INCSLOUPCE) > 0 SET @INCSLOUPCE =  LEFT(@INCSLOUPCE, LEN(@INCSLOUPCE) -1 )

	
	IF (LEN(@SLOUPCE)>=2) INSERT INTO #INDEXY SELECT @TABULKA, @INDEXNAME, LEFT(@SLOUPCE, LEN(@SLOUPCE) -1), @INCSLOUPCE, @filter_definition
END
CLOSE CUR
DEALLOCATE CUR


SELECT 'BEGIN TRY IF NOT EXISTS(SELECT * FROM SYS.indexes WHERE NAME = '' + INDEXNAME +  '') AND OBJECT_ID('' + TABLENAME+ '') IS NOT NULL CREATE INDEX ' 
+ INDEXNAME +  ' ON ' + TABLENAME + ' ( ' + SLOUPCE + ')' + CASE WHEN filter_definition <> '' THEN ' WHERE ' + filter_definition ELSE '' END
+ CASE WHEN LEN(INCSLOUPCE) > 0 THEN ' INCLUDE ( ' + INCSLOUPCE + ' )' ELSE '' END 
+' PRINT ''OK ... ' + INDEXNAME + ''' END TRY BEGIN CATCH PRINT ''Index ' + INDEXNAME + ' se nepodarilo vytvorit '' END CATCH'
--+ CHAR(13) +'GO' + CHAR(13) 
FROM #INDEXY 
SET NOCOUNT OFF

select * from sys.indexes
select * from sys.index_columns

-----------------------------------------







with dotaz as
(
select so.name, so2.name as ParentName,
case si.rsc_type
when 1 then ' Resource (not used)'
when 2 then 'Database'
when 3 then 'File'
when 4 then 'Index'
when 5 then 'Table'
when 6 then 'Page'
when 7 then 'Key'
when 8 then 'Extent'
when 9 then 'RID (Row ID)'
when 10 then 'Application'
end AS rsc_type


,case req_mode
when 0 then ' . No access is granted to the resource. Serves as a placeholder.'
when 1 then ' Sch-S (Schema stability). Ensures that a schema element, such as a table or index, is not dropped while any session holds a schema stability lock on the schema element.'
when 2 then ' Sch-M (Schema modification). Must be held by any session that wants to change the schema of the specified resource. Ensures that no other sessions are referencing the indicated object.'
when 3 then ' S (Shared). The holding session is granted shared access to the resource.'
when 4 then ' U (Update). Indicates an update lock acquired on resources that may eventually be updated. It is used to prevent a common form of deadlock that occurs when multiple sessions lock resources for potential update in the future.'
when 5 then ' X (Exclusive). The holding session is granted exclusive access to the resource.'
when 6 then ' IS (Intent Shared). Indicates the intention to place S locks on some subordinate resource in the lock hierarchy.'
when 7 then ' IU (Intent Update). Indicates the intention to place U locks on some subordinate resource in the lock hierarchy.'
when 8 then ' IX (Intent Exclusive). Indicates the intention to place X locks on some subordinate resource in the lock hierarchy.'
when 9 then ' SIU (Shared Intent Update). Indicates shared access to a resource with the intent of acquiring update locks on subordinate resources in the lock hierarchy.'
when 10 then ' SIX (Shared Intent Exclusive). Indicates shared access to a resource with the intent of acquiring exclusive locks on subordinate resources in the lock hierarchy.'
when 11 then ' UIX (Update Intent Exclusive). Indicates an update lock hold on a resource with the intent of acquiring exclusive locks on subordinate resources in the lock hierarchy.'
when 12 then ' BU. Used by bulk operations.'
when 13 then ' RangeS_S (Shared Key-Range and Shared Resource lock). Indicates serializable range scan.'
when 14 then ' RangeS_U (Shared Key-Range and Update Resource lock). Indicates serializable update scan.'
when 15 then ' RangeI_N (Insert Key-Range and  Resource lock). Used to test ranges before inserting a new key into an index.'
when 16 then ' RangeI_S. Key-Range Conversion lock, created by an overlap of RangeI_N and S locks.'
when 17 then ' RangeI_U. Key-Range Conversion lock, created by an overlap of RangeI_N and U locks.'
when 18 then ' RangeI_X. Key-Range Conversion lock, created by an overlap of RangeI_N and X locks.'
when 19 then ' RangeX_S. Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_S. locks.'
when 20 then ' RangeX_U. Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_U locks.'
when 21 then ' RangeX_X (Exclusive Key-Range and Exclusive Resource lock). This is a conversion lock used when updating a key in a range.'
end as req_mode



, sp.loginame, sp.program_name
, SUBSTRING(QT.TEXT,0,CASE WHEN LEN(QT.TEXT) <= 5000 THEN LEN(QT.TEXT) ELSE 5000 END) AS ZACATEKSTMT
, SUBSTRING(QT.TEXT,CASE WHEN SP.STMT_START/2 >= 0 THEN SP.STMT_START/2 + 1 ELSE 0 END, CASE WHEN SP.STMT_END/2 - SP.STMT_START/2 > 1 THEN SP.STMT_END/2 - SP.STMT_START/2 ELSE 100000 END) AS AKTUALNIPRIKAZ
, GETDATE() AktualniCas
, SE.transaction_id
--, count(1) CNT
from sys.syslockinfo si
join sys.objects so on si.rsc_objid = so.object_id and si.rsc_dbid = db_id()
join sys.sysprocesses sp on si.req_spid = sp.spid
left join sys.objects so2 on so.parent_object_id = so2.object_id and si.rsc_dbid = db_id()
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.SQL_HANDLE) QT ------------------------------------------------------------------------ POKUD CHCI "PRAZDNE RADKY", TAK NAHRADIT "CROSS APPLY" ZA "OUTER APPLY" 
LEFT JOIN SYS.DM_TRAN_SESSION_TRANSACTIONS SE WITH (NOLOCK) ON SP.SPID = SE.SESSION_ID
)

select name, ParentName, rsc_type, req_mode, loginame, program_name, zacatekstmt, AktualniPrikaz, AktualniCas, transaction_id, count(1) CNT from dotaz
where loginame <> 'sa'
group by name, ParentName, rsc_type, req_mode, loginame, program_name, zacatekstmt, AktualniPrikaz, AktualniCas, transaction_id 
order by CNT desc













----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


--				.
--				KONTROLA PAMETI
--
--				NA ZAKLADE TETO KONTROLY ZJISTIME, KOLIK PAMETI VYUZIVAJI JEDNOTLIVE DB
--

----------------------------------------------------------------

----------------- Vyuziti pameti --------------------
select physical_memory_in_use_kb/1024/1024 AS physical_memory_in_use_GB, * from sys.dm_os_process_memory

----------------- Database celkem --------------------

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

/*
Process: Working Set
SQL Server: Buffer Manager: Buffer Cache Hit Ratio
SQL Server: Buffer Manager: Total Pages
SQL Server: Memory Manager: Total Server Memory (KB)
*/


----------------- A jeste konkretni DB a konkretni objekty --------------------
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




   -- To get the total physical memory installed on SQL Server
SELECT [total_physical_memory_kb] / 1024 AS [Total_Physical_Memory_In_MB]
    ,[available_page_file_kb] / 1024 AS [Available_Physical_Memory_In_MB]
    ,[total_page_file_kb] / 1024 AS [Total_Page_File_In_MB]
    ,[available_page_file_kb] / 1024 AS [Available_Page_File_MB]
    ,[kernel_paged_pool_kb] / 1024 AS [Kernel_Paged_Pool_MB]
    ,[kernel_nonpaged_pool_kb] / 1024 AS [Kernel_Nonpaged_Pool_MB]
    ,[system_memory_state_desc] AS [System_Memory_State_Desc]
FROM [master].[sys].[dm_os_sys_memory]
 
--To get the minimum and maximum size of memory configured for SQL Server.
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











----------------- Countery jako takove --------------------
SELECT *    FROM sys.dm_os_performance_counters 



SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 as BufferCacheHitRatio
FROM sys.dm_os_performance_counters  a
JOIN  (SELECT cntr_value, OBJECT_NAME 
    FROM sys.dm_os_performance_counters  
    WHERE counter_name = 'Buffer cache hit ratio base'
        AND OBJECT_NAME LIKE '%:Buffer Manager%') b ON  a.OBJECT_NAME = b.OBJECT_NAME
WHERE a.counter_name = 'Buffer cache hit ratio'
AND a.OBJECT_NAME LIKE '%:Buffer Manager%'


SELECT [object_name],
[counter_name],
[cntr_value] FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Manager%'
AND [counter_name] = 'Page life expectancy'





----------------------------------------------------------------------------------------------------------------------------------------------------------


--				X.
--				NASTAVENI MAXDOP x COST TRESHOLD
--

-- VSECHNY DOTAZY, KTERE POUZIVAJI PARALELNI PLAN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
WITH XMLNAMESPACES   
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
SELECT  
     query_plan AS CompleteQueryPlan, 
     n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText, 
     n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel, 
     n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost, 
     n.query('.') AS ParallelSubTreeXML,  
     ecp.usecounts, 
     ecp.size_in_bytes 
	 , QS.creation_time, QS.last_execution_time, QS.execution_count
FROM sys.dm_exec_cached_plans AS ecp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
LEFT JOIN (SELECT plan_handle, MIN(creation_time) AS creation_time, MAX(last_execution_time) AS last_execution_time, SUM(execution_count) AS execution_count
			FROM sys.DM_EXEC_QUERY_STATS GROUP BY plan_handle ) QS on ecp.plan_handle  = qs.plan_handle
WHERE  n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1 
order by convert(numeric(19,6), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') ) desc




----------------------------------------------------------------------------------------------------------------------------------------------------------


--				X.
--				KONTROLA VSECH DATABAZI A JEJICH VELIKOSTI
--

-------------------------------------------------------------------------
--- Mrknout na celkový poèet databází a jejich velikost

----- Celková velikost všech online databází

SELECT type_desc, CONVERT(INT, SUM(SIZE)  * 8.0 / 1024 /1024) SIZE_GB, CONVERT(INT, SUM(SIZE)  * 8.0 / 1024) SIZE_MB
    FROM SYS.MASTER_FILES
	WHERE database_id in (select database_id from sys.databases where state_desc = 'ONLINE')
	GROUP BY type_desc
	ORDER BY 1 DESC


----- Velikosti a parametry jednotlivych databazi na serveru (pouze online databaze)

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

 

 select * from sys.columns sc join sys.objects so on sc.object_id = so.object_id 
 where so.name = 'TabHGlob'
 and sc.name like '%Arch%'



--------------------------- Archivace zmen ---------------------------------
 select 
convert(int,ArchivaceZmenDenik ) + convert(int, ArchivaceZmenKmenZbozi ) + convert(int, ArchivaceZmenDokZbo ) + convert(int, ArchivaceZmenPokladna ) + convert(int, ArchivaceZmenNC ) + convert(int, ArchivaceZmenKontaktJednani ) + convert(int, ArchivaceZmenBankSp
  ) + convert(int, ArchivaceZmenZamMzd ) + convert(int, ArchivaceZmenCisZam ) + convert(int, ArchivaceZmenMzdOdpPolMzd ) + convert(int, ArchivaceZmenDosleObjH20 ) + convert(int, ArchivaceZmenSkupinaZbozi ) + convert(int, ArchivaceZmenDosleObjH02)
 AS ArchivaceZmenCelkem
 , ArchivaceZmenDenik , ArchivaceZmenKmenZbozi, ArchivaceZmenDokZbo, ArchivaceZmenPokladna, ArchivaceZmenNC, ArchivaceZmenKontaktJednani, ArchivaceZmenBankSp
 , ArchivaceZmenZamMzd, ArchivaceZmenCisZam, ArchivaceZmenMzdOdpPolMzd, ArchivaceZmenDosleObjH20, ArchivaceZmenSkupinaZbozi, ArchivaceZmenDosleObjH02
 from TabHGlob
 



----------------------------------------------------------------------------------------------------------------------------------------------------------


--				XI.
--				ANALYZA UDAJU ZAZNAMENANYCH V TRACE
--

-------------------------------------------------------------------------


SELECT 
	EventClass
	, ApplicationName
	, DatabaseName
	, ObjectName
	, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(MAX),TextData)
		,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','') AS TextData
	, MAX(CONVERT(NVARCHAR(MAX),TextData)) AS TextDataHodnoty
	, SUM(Duration)/1000000.0 As SumDurationSec
	, COUNT(1) AS CNT
	, SUM(Duration)/1000000.0/COUNT(1) AS AvgDurationSec
	, AVG(NestLevel) AS AvgNestLevel
INTO tempdb..JKO_TRACE101
FROM tempdb..JKO_TRACE01
GROUP BY
	EventClass
	, ApplicationName
	, DatabaseName
	, ObjectName
	, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(MAX),TextData)
	,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')

SELECT TextDataHodnoty, SumDurationSec, CNT, * FROM tempdb..JKO_TRACE101 WHERE EventClass in (41, 45 /*stmt only*/) ORDER BY 2 DESC


-------------------------------------------------------------------------
-- Porovnani dvou ruznych trace
-- Prvni je v souboru "JKO_TRACE01"
-- Druhy je v souboru "JKO_TRACE04"

DECLARE @Start TIME
DECLARE @End TIME

SELECT @Start = MAX(CONVERT(TIME,StartTime)) FROM (SELECT MIN(StartTime) AS StartTime FROM JKO_TRACE01 UNION SELECT MIN(StartTime) FROM JKO_TRACE04) AS X
SELECT @End   = MIN(CONVERT(TIME,StartTime)) FROM (SELECT MAX(StartTime) AS StartTime FROM JKO_TRACE01 UNION SELECT MAX(StartTime) FROM JKO_TRACE04) AS X

SELECT 
CONVERT(DATE, StartTime) AS Datum
, SUM(CASE WHEN Duration <= 1000000 THEN 1 ELSE 0 END) AS [Pod 1 sec]
, SUM(CASE WHEN Duration BETWEEN  1000001  AND  20000000 THEN 1 ELSE 0 END) AS [1-2 sec]
, SUM(CASE WHEN Duration BETWEEN  2000001  AND  50000000 THEN 1 ELSE 0 END) AS [2-5 sec]
, SUM(CASE WHEN Duration BETWEEN  5000001  AND  10000000 THEN 1 ELSE 0 END) AS [5-10 sec]
, SUM(CASE WHEN Duration BETWEEN  10000001 AND  20000000 THEN 1 ELSE 0 END) AS [10-20 sec]
, SUM(CASE WHEN Duration BETWEEN  20000001 AND  50000000 THEN 1 ELSE 0 END) AS [20-50 sec]
, SUM(CASE WHEN Duration BETWEEN  50000001 AND  100000000 THEN 1 ELSE 0 END) AS [50-100 sec]
, SUM(CASE WHEN Duration > 100000000 THEN 1 ELSE 0 END) AS [Nad 100 sec]
FROM 
(
SELECT * FROM JKO_TRACE01 WHERE Duration IS NOT NULL AND CONVERT(TIME, StartTime) BETWEEN @Start AND @End
UNION ALL
SELECT * FROM JKO_TRACE04 WHERE Duration IS NOT NULL AND CONVERT(TIME, StartTime) BETWEEN @Start AND @End
) x
GROUP BY CONVERT(DATE, StartTime) 

-------------------------------------------------------------------------


SELECT CONVERT(DATE, StartTime) AS Datum, AVG(Duration)/1000000.0 AS Prumer, COUNT(1) AS Pocet
FROM (SELECT * FROM JKO_TRACE01 WHERE Duration IS NOT NULL AND CONVERT(TIME, StartTime) BETWEEN @Start AND @End
UNION ALL SELECT * FROM JKO_TRACE04 WHERE Duration IS NOT NULL AND CONVERT(TIME, StartTime) BETWEEN @Start AND @End ) x GROUP BY CONVERT(DATE, StartTime) 





--------------- GREEN - funkce -----------------------------------
select 
  datediff(SECOND, started, ended) --doba provedeni funkce v sec
, cpu
, physical_io
, version_app
, popis
, nazev
, f.typ
, jmeno
, prijmeni
, e_mail
, *
  from lcs.auditlog_hlavicka h
join lcs.auditlog_polozka p on h.cislo_transakce = p.cislo_transakce
join lcs.funjects f on h.funject = f.cislo_funjectu
join lcs.zamestnanci z on h.pachatel = z.cislo_subjektu
where funject = 2144 and started > dateadd(DAY, -23, getdate()) 
order by started desc


--------------- Vyhledani prikazu zpusobujicich retezove blokace -----------------------------------


SELECT S1 AS spid, COUNT(1) CNT, 'KILL ' + CONVERT(NVARCHAR(5), S1) AS PrikazUkonceniBlokaci  FROM
(
SELECT DISTINCT S1.spid AS s1, S1.blocked AS b1, S2.spid AS s2, S2.blocked AS b2, S3.spid AS s3, S3.blocked AS b3, S4.spid AS s4, S4.blocked AS b4 FROM SYS.SYSPROCESSES S1
JOIN SYS.SYSPROCESSES S2 ON S1.spid = s2.blocked AND S1.blocked <> s2.spid
LEFT JOIN SYS.SYSPROCESSES S3 ON S2.spid = s3.blocked AND S2.blocked <> s3.spid 
LEFT JOIN SYS.SYSPROCESSES S4 ON S3.spid = s4.blocked AND S3.blocked <> s4.spid 
WHERE (s1.blocked = 0 OR s1.blocked = s1.spid) 
) X GROUP BY S1 ORDER BY CNT DESC










----------------------------------------------------------------------------------------------------------------------------------------------------------


--				.
--				ROZKOPIROVANI INDEXU IXe DO VSECH OSTATNICH DATABAZI
--
--

-- Nejprve prohledame vsechny databaze a najdeme v nich vsechny IXe indexy. Vysledek nasypeme do tabulky.

SET NOCOUNT ON

IF OBJECT_ID( 'TEMPDB..#INDEXY'  ) IS NOT NULL DROP TABLE #INDEXY 
CREATE TABLE #INDEXY (TABLENAME NVARCHAR(128), INDEXNAME NVARCHAR(128), SLOUPCE NVARCHAR(1000), INCSLOUPCE NVARCHAR(1000), filter_definition NVARCHAR(MAX))


EXEC sp_MSforeachdb 
N' 
USE ? 
DECLARE @TABULKA NVARCHAR(128), @INDEXNAME NVARCHAR(128), @OBJECT_ID INT, @INDEX_ID INT, @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX), @filter_definition NVARCHAR(MAX), @database NVARCHAR(MAX)

	DECLARE CUR CURSOR LOCAL FOR
	SELECT OBJECT_NAME(OBJECT_ID), OBJECT_ID, NAME, INDEX_ID, filter_definition 
		FROM SYS.INDEXES I
		WHERE OBJECT_ID IN (SELECT OBJECT_ID FROM SYS.INDEXES WHERE name LIKE  ''IXe%'' )

	OPEN CUR
	WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @TABULKA, @OBJECT_ID, @INDEXNAME ,@INDEX_ID, @filter_definition 
		IF @@FETCH_STATUS <> 0 BREAK
		SET @SLOUPCE =  ''''
		SET @INCSLOUPCE = '''' 

		SELECT @SLOUPCE =  @SLOUPCE + SC.NAME 
		+ CASE WHEN IC.is_descending_key = 1 THEN  '' DESC ''  ELSE ''''  END
		+  '',''   --CONVERT(NVARCHAR(10), COLUMN_ID) +  _  
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 0
		AND I.name LIKE  ''IXe%''
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID

		SELECT @INCSLOUPCE =  @INCSLOUPCE + SC.NAME +  '',''   --CONVERT(NVARCHAR(10), COLUMN_ID) +  _ 
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 1
		AND I.name LIKE  ''IXe%'' 
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID
		IF LEN(@INCSLOUPCE) > 0 SET @INCSLOUPCE =  LEFT(@INCSLOUPCE, LEN(@INCSLOUPCE) -1 )

	
		IF (LEN(@SLOUPCE)>=2) 
		AND NOT EXISTS(SELECT * FROM #INDEXY WHERE INDEXNAME = @INDEXNAME)
		INSERT INTO #INDEXY SELECT @TABULKA, @INDEXNAME, LEFT(@SLOUPCE, LEN(@SLOUPCE) -1), @INCSLOUPCE, @filter_definition
	END
	CLOSE CUR
	DEALLOCATE CUR
' 

-- A potom vsechny tyto indexy nasypeme do vsech databazi


EXEC sp_MSforeachdb 
N'
USE ?


SET QUOTED_IDENTIFIER ON
PRINT  ''Database: ''  + DB_NAME()

DECLARE @cmd NVARCHAR(MAX), @TABLENAME NVARCHAR(150), @INDEXNAME NVARCHAR(150), @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX), @filter_definition NVARCHAR(MAX)

DECLARE CUR CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT TABLENAME, INDEXNAME, SLOUPCE, INCSLOUPCE, filter_definition FROM #INDEXY 

OPEN CUR

WHILE 1 = 1
	BEGIN
	FETCH CUR INTO @TABLENAME, @INDEXNAME, @SLOUPCE, @INCSLOUPCE, @filter_definition 
	IF @@FETCH_STATUS <> 0 BREAK
	SELECT @cmd = 
	N'' 
	BEGIN TRY IF NOT EXISTS(SELECT * FROM SYS.indexes WHERE NAME = ''''''  + @INDEXNAME +  '''''' ) AND OBJECT_ID( '''''' + @TABLENAME+  '''''') IS NOT NULL CREATE INDEX  '' 
	+ @INDEXNAME +  N'' ON '' + @TABLENAME + N'' (  '' + @SLOUPCE + N'') ''
	+ CASE WHEN LEN(@INCSLOUPCE) > 0 THEN N''  INCLUDE (  '' + @INCSLOUPCE + N''  ) '' ELSE N''''  END 
	+ CASE WHEN @filter_definition <> ''''  THEN N'' WHERE ''  + @filter_definition ELSE N''''  END
	+ N''  PRINT  ''''OK ...  '' + @INDEXNAME + N''''''  
	END TRY 
	BEGIN CATCH 
	PRINT ERROR_MESSAGE()
	PRINT CHAR(13) + '''' Index  '' + @INDEXNAME + N''  se nepodarilo vytvorit !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  ''''
	END CATCH 
	PRINT  ''''------------------------------------------''''   ''
	EXEC(@cmd)
	END
' 


SET NOCOUNT OFF

/*

----------------------------------------------------------------------------------------------------------------------------------------------------------


--				.
--				ROZKOPIROVANI INDEXU IXe DO VSECH OSTATNICH DATABAZI
--
--

-- Nejprve prohledame vsechny databaze a najdeme v nich vsechny IXe indexy. Vysledek nasypeme do tabulky.

SET NOCOUNT ON

IF OBJECT_ID('TEMPDB..#INDEXY ') IS NOT NULL DROP TABLE #INDEXY 
CREATE TABLE #INDEXY (TABLENAME NVARCHAR(128), INDEXNAME NVARCHAR(128), SLOUPCE NVARCHAR(1000), INCSLOUPCE NVARCHAR(1000), filter_definition NVARCHAR(MAX))


EXEC sp_MSforeachdb 
'
USE ? 
DECLARE @TABULKA NVARCHAR(128), @INDEXNAME NVARCHAR(128), @OBJECT_ID INT, @INDEX_ID INT, @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX), @filter_definition NVARCHAR(MAX), @database NVARCHAR(MAX)

	DECLARE CUR CURSOR LOCAL FOR
	SELECT OBJECT_NAME(OBJECT_ID), OBJECT_ID, NAME, INDEX_ID, filter_definition 
		FROM SYS.INDEXES I
		WHERE OBJECT_ID IN (SELECT OBJECT_ID FROM SYS.INDEXES WHERE name LIKE ''IXe%'')

	OPEN CUR
	WHILE 1 = 1
	BEGIN
		FETCH CUR INTO @TABULKA, @OBJECT_ID, @INDEXNAME ,@INDEX_ID, @filter_definition 
		IF @@FETCH_STATUS <> 0 BREAK
		SET @SLOUPCE = ''
		SET @INCSLOUPCE = ''

		SELECT @SLOUPCE =  @SLOUPCE + SC.NAME 
		+ CASE WHEN IC.is_descending_key = 1 THEN '' DESC '' ELSE '''' END
		+ ', ' --CONVERT(NVARCHAR(10), COLUMN_ID) + ''_'' 
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 0
		AND I.name LIKE ''IXe%''
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID

		SELECT @INCSLOUPCE =  @INCSLOUPCE + SC.NAME + '', '' --CONVERT(NVARCHAR(10), COLUMN_ID) + ''_''
		FROM SYS.INDEXES I
			JOIN SYS.INDEX_COLUMNS IC ON I.OBJECT_ID = IC.OBJECT_ID AND I.INDEX_ID = IC.INDEX_ID
			JOIN SYS.COLUMNS SC ON IC.OBJECT_ID = SC.OBJECT_ID AND IC.COLUMN_ID = SC.COLUMN_ID
		WHERE I.OBJECT_ID = @OBJECT_ID AND I.INDEX_ID = @INDEX_ID
		AND IS_INCLUDED_COLUMN = 1
		AND I.name LIKE ''IXe%''
		ORDER BY I.OBJECT_ID, I.INDEX_ID, IC.INDEX_COLUMN_ID
		IF LEN(@INCSLOUPCE) > 0 SET @INCSLOUPCE =  LEFT(@INCSLOUPCE, LEN(@INCSLOUPCE) -1 )

	
		IF (LEN(@SLOUPCE)>=2) 
		AND NOT EXISTS(SELECT * FROM #INDEXY WHERE INDEXNAME = @INDEXNAME)
		INSERT INTO #INDEXY SELECT @TABULKA, @INDEXNAME, LEFT(@SLOUPCE, LEN(@SLOUPCE) -1), @INCSLOUPCE, @filter_definition
	END
	CLOSE CUR
	DEALLOCATE CUR
'

-- A potom vsechny tyto indexy nasypeme do vsech databazi


EXEC sp_MSforeachdb 
N'
USE ?
SET QUOTED_IDENTIFIER ON
PRINT ''Database: '' + DB_NAME()

DECLARE @cmd NVARCHAR(MAX), @TABLENAME NVARCHAR(150), @INDEXNAME NVARCHAR(150), @SLOUPCE NVARCHAR(MAX), @INCSLOUPCE NVARCHAR(MAX), @filter_definition NVARCHAR(MAX)

DECLARE CUR CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT TABLENAME, INDEXNAME, SLOUPCE, INCSLOUPCE, filter_definition FROM #INDEXY 

OPEN CUR

WHILE 1 = 1
	BEGIN
	FETCH CUR INTO @TABLENAME, @INDEXNAME, @SLOUPCE, @INCSLOUPCE, @filter_definition 
	IF @@FETCH_STATUS <> 0 BREAK
	SELECT @cmd = 
	N''
	BEGIN TRY IF NOT EXISTS(SELECT * FROM SYS.indexes WHERE NAME = '''''' + @INDEXNAME +  '''''') AND OBJECT_ID('''' + @TABLENAME+ '''') IS NOT NULL CREATE INDEX '' 
	+ @INDEXNAME +  N'' ON '' + @TABLENAME + N'' ( '' + @SLOUPCE + N'')''
	+ CASE WHEN LEN(@INCSLOUPCE) > 0 THEN N'' INCLUDE ( '' + @INCSLOUPCE + N'' )'' ELSE N'''' END 
	+ CASE WHEN @filter_definition <> '''' THEN N'' WHERE '' + @filter_definition ELSE N'''' END
	+N'' PRINT ''''OK ... '''' + @INDEXNAME + N'''''' END TRY 
	BEGIN CATCH 
	PRINT ERROR_MESSAGE()
	PRINT CHAR(13) + ''''Index '' + @INDEXNAME + N'' se nepodarilo vytvorit !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'''' END CATCH''
	+ CHAR(13)
	PRINT ''------------------------------------------' '
	PRINT @cmd
	PRINT ''------------------------------------------' '
	EXEC(@cmd)
	END'


SET NOCOUNT OFF

*/







SELECT 'ALTER DATABASE ' + DB_NAME(database_id) + ' MODIFY FILE (NAME=' + name + ',FILEGROWTH=50MB)'
FROM SYS.master_files
WHERE TYPE = 0 /*ROWS*/
AND state = 0 /*ONLINE*/
AND DB_NAME(database_id) like '%Helios%'
AND is_percent_growth = 0
AND growth < (128*50 /*50MB*/)


SELECT 'ALTER DATABASE ' + DB_NAME(database_id) + ' SET AUTO_SHRINK OFF'
FROM SYS.databases
WHERE name LIKE 'Helios%' AND is_auto_shrink_on = 1



-------------------- OPTIMIZE FOR AD HOC WORKLOADS ---------------------------------------

IF EXISTS (
        -- this is for 2008 and up
        SELECT 1
        FROM sys.configurations
        WHERE NAME = 'optimize for ad hoc workloads'
        )
BEGIN
    DECLARE @AdHocSizeInMB DECIMAL(14, 2)
        ,@TotalSizeInMB DECIMAL(14, 2)
        ,@ObjType NVARCHAR(34)

    SELECT @AdHocSizeInMB = SUM(CAST((
                    CASE 
                        WHEN usecounts = 1
                            AND LOWER(objtype) = 'adhoc'
                            THEN size_in_bytes
                        ELSE 0
                        END
                    ) AS DECIMAL(14, 2))) / 1048576
        ,@TotalSizeInMB = SUM(CAST(size_in_bytes AS DECIMAL(14, 2))) / 1048576
    FROM sys.dm_exec_cached_plans

    SELECT 'SQL Server Configuration' AS GROUP_TYPE
        ,' Total cache plan size (MB): ' + cast(@TotalSizeInMB AS VARCHAR(max)) + '. Current memory occupied by adhoc plans only used once (MB):' + cast(@AdHocSizeInMB AS VARCHAR(max)) + '.  Percentage of total cache plan occupied by adhoc plans only used once :' + cast(CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 AS DECIMAL(14, 2)) AS VARCHAR(max)) + '%' + ' ' AS COMMENTS
        ,' ' + CASE 
            WHEN @AdHocSizeInMB > 200
                OR ((@AdHocSizeInMB / @TotalSizeInMB) * 100) > 25 -- 200MB or > 25%
                THEN 'Switch on Optimize for ad hoc workloads as it will make a significant difference. Ref: http://sqlserverperformance.idera.com/memory/optimize-ad-hoc-workloads-option-sql-server-2008/. http://www.sqlskills.com/blogs/kimberly/post/procedure-cache-and-optimizing-for-adhoc-workloads.aspx'
            ELSE 'Setting Optimize for ad hoc workloads will make little difference !!'
            END + ' ' AS RECOMMENDATIONS
END




-- Ulozene exekucni plany ----------------

SELECT
	databases.name,
	SUM(CAST(dm_exec_cached_plans.size_in_bytes AS BIGINT)) AS plan_cache_size_in_bytes,
	COUNT(*) AS number_of_plans
FROM sys.dm_exec_query_stats query_stats 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS query_plan
INNER JOIN sys.databases
ON databases.database_id = query_plan.dbid
INNER JOIN sys.dm_exec_cached_plans
ON dm_exec_cached_plans.plan_handle = query_stats.plan_handle
GROUP BY databases.name




-------------------------------------------------------------------------------------------------
--VYTVORI JOB, KTERY BUDE LOGOVAT BLOKACE, TAK JAKO TO MAJI NA GREENU


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



-------------------------------------------------------------------------------------------------
-- Kontrola navrzenych indexu vcetne cetnosti pouziti a odhadu zlepseni



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
, PlanMissingIndexes
AS (SELECT query_plan, usecounts
    FROM sys.dm_exec_cached_plans cp
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
    WHERE qp.query_plan.exist('//MissingIndexes') = 1)
, MissingIndexes
AS (SELECT stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]', 'sysname') AS DatabaseName,
           stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Schema)[1]', 'sysname') AS SchemaName,
           stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]', 'sysname') AS TableName,
           stmt_xml.value('(QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]', 'float') AS Impact,
           ISNULL(CAST(stmt_xml.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS FLOAT), 0) AS Cost,
           pmi.usecounts UseCounts,
           STUFF((SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
             FROM stmt_xml.nodes('//ColumnGroup') AS t(cg)
             CROSS APPLY cg.nodes('Column') AS r(c)
             WHERE cg.value('(@Usage)[1]', 'sysname') = 'EQUALITY'
             FOR XML PATH('')),1,2,''
                ) AS equality_columns,
           STUFF(( SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
             FROM stmt_xml.nodes('//ColumnGroup') AS t(cg)
             CROSS APPLY cg.nodes('Column') AS r(c)
             WHERE cg.value('(@Usage)[1]', 'sysname') = 'INEQUALITY'
             FOR XML PATH('')),1,2,''
                ) AS inequality_columns,
           STUFF((SELECT DISTINCT ', ' + c.value('(@Name)[1]', 'sysname')
             FROM stmt_xml.nodes('//ColumnGroup') AS t(cg)
             CROSS APPLY cg.nodes('Column') AS r(c)
             WHERE cg.value('(@Usage)[1]', 'sysname') = 'INCLUDE'
             FOR XML PATH('')),1,2,''
                ) AS include_columns,
           query_plan,
           stmt_xml.value('(@StatementText)[1]', 'varchar(4000)') AS sql_text
    FROM PlanMissingIndexes pmi
    CROSS APPLY query_plan.nodes('//StmtSimple') AS stmt(stmt_xml)
    WHERE stmt_xml.exist('QueryPlan/MissingIndexes') = 1)

SELECT TOP 200
       DatabaseName,
       SchemaName,
       TableName,
       equality_columns,
       inequality_columns,
       include_columns,
       UseCounts,
       Cost,
       Cost * UseCounts [AggregateCost],
       Impact,
       query_plan
        ,'USE ' + databaseName + ' CREATE INDEX IXe__' + REPLACE(REPLACE(REPLACE(TableName, '[', ''), ']','') + N'__'
	   + REPLACE(REPLACE(REPLACE(ISNULL(equality_columns,'') + ISNULL(', ' +inequality_columns, '') + ISNULL(', ' +include_columns, '') 
	   , '[', ''), ']',''),',','__'),' ','') 
	   + ' ON ' + TableName + '(' + ISNULL(equality_columns,'') + ISNULL(', ' +inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + include_columns + ')', '')
FROM MissingIndexes
--WHERE DatabaseName = QUOTENAME(DB_NAME())
ORDER BY UseCounts DESC;



----Latence a pocty pri zapisu do souboru

SELECT  DB_NAME(a.database_id) AS [Database Name] ,
        b.name + N' [' + b.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + N']' AS [Logical File Name] ,
        UPPER(SUBSTRING(b.physical_name, 1, 2)) AS [Drive] ,
        CAST(( ( a.size_on_disk_bytes / 1024.0 ) / (1024.0*1024.0) ) AS DECIMAL(9,2)) AS [Size (GB)] ,
        a.io_stall_read_ms AS [Total IO Read Stall] ,
        a.num_of_reads AS [Total Reads] ,
        CASE WHEN a.num_of_bytes_read > 0 
            THEN CAST(a.num_of_bytes_read/1024.0/1024.0/1024.0 AS NUMERIC(23,1))
            ELSE 0 
        END AS [GB Read],
        CAST(a.io_stall_read_ms / ( 1.0 * a.num_of_reads ) AS INT) AS [Avg Read Stall (ms)] ,
        CASE 
            WHEN b.type = 0 THEN 30 /* data files */
            WHEN b.type = 1 THEN 5 /* log files */
            ELSE 0
        END AS [Max Rec Read Stall Avg],
        a.io_stall_write_ms AS [Total IO Write Stall] ,
        a.num_of_writes [Total Writes] ,
        CASE WHEN a.num_of_bytes_written > 0 
            THEN CAST(a.num_of_bytes_written/1024.0/1024.0/1024.0 AS NUMERIC(23,1))
            ELSE 0 
        END AS [GB Written],
        CAST(a.io_stall_write_ms / ( 1.0 * a.num_of_writes ) AS INT) AS [Avg Write Stall (ms)] ,
        CASE 
            WHEN b.type = 0 THEN 30 /* data files */
            WHEN b.type = 1 THEN 2 /* log files */
            ELSE 0
        END AS [Max Rec Write Stall Avg] ,
        b.physical_name AS [Physical File Name],
        CASE
            WHEN b.name = 'tempdb' THEN 'N/A'
            WHEN b.type = 1 THEN 'N/A' /* log files */
            ELSE 'PAGEIOLATCH*'
        END AS [Read-Related Wait Stat],
        CASE
            WHEN b.type = 1 THEN 'WRITELOG' /* log files */
            WHEN b.name = 'tempdb' THEN 'xxx' /* tempdb data files */
            WHEN b.type = 0 THEN 'ASYNC_IO_COMPLETION' /* data files */
            ELSE 'xxx'
        END AS [Write-Related Wait Stat],
        GETDATE() AS [Sample Time],
        b.type_desc
       FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS a
                    INNER JOIN sys.master_files AS b ON a.file_id = b.file_id
                                                                                AND a.database_id = b.database_id
       WHERE   a.num_of_reads > 0
                    AND a.num_of_writes > 0
       ORDER BY  CAST(a.io_stall_read_ms / ( 1.0 * a.num_of_reads ) AS INT) DESC
