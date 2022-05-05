	use XXX;	--< VYBRAT DATABAZI

	SELECT 
		DB_NAME(dbid) as DBName, 
		COUNT(dbid) as NumberOfConnections,
		loginame as LoginName
	--SELECT *
	FROM
		sys.sysprocesses
	WHERE 
		dbid > 0
	GROUP BY 
		dbid, loginame
	;