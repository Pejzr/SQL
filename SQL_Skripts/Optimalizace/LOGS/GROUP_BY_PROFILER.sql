----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--														 ZGRUPOVANI DAT Z PROFILERU																		--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			LOGUJE PRIKAZY DELSI NEZ 10 MILISEKUND, KTERE NEJSOU SPOUSTENY PRES MANAGEMENT STUDIO
----------------------------------------------------------------------------------------------------------------------------------------------------------

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
	INTO master..MPE_TRACE101
	FROM master..MPE_TRACE01
	GROUP BY
		EventClass
		, ApplicationName
		, DatabaseName
		, ObjectName
		, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(MAX),TextData)
		,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')

	SELECT TextDataHodnoty, SumDurationSec, CNT, * FROM master..MPE_TRACE101 
	ORDER BY 2 DESC