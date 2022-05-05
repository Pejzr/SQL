----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--								POUSTI SE AZ NAKONEC Z DUVODU PREPISU EXEKUCNICH PLANU PRI ZMENE PARAMETRU MAXDOP										--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			    VYBRANE PARAMETRY SERVERU
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
	NAME
	, VALUE_IN_USE
	, DESCRIPTION
	, CASE 
		WHEN NAME = 'cost threshold for parallelism' AND VALUE_IN_USE = 20 THEN 'OK'	--DOPORUCENA HODNOTA 20
		WHEN NAME = 'max degree of parallelism' AND VALUE_IN_USE = 8 THEN 'OK'		--DOPORUCENA HODNOTA 4, NEBO 8
		WHEN NAME = 'optimize for ad hoc workloads' AND VALUE_IN_USE = 1 THEN 'OK'	--DOPORUCENA HODNOTA 1
		WHEN NAME = 'blocked process threshold (s)' AND VALUE_IN_USE = 0 THEN 'OK'	--DOPORUCENA HODNOTA 0
		ELSE 'Tezko rict ...'
		END AS Info
	 FROM SYS.configurations
	 WHERE configuration_id IN (1538, 1539, 1569, 1581)	

	/*
		!!!		RECONFIGURE U MAXDOP PUSTIT AZ NAKONEC, MAXDOP VYÈISTÍ CACHE PAMETI	!!!

		EXEC sp_configure 'cost threshold for parallelism', 50;
		EXEC sp_configure 'max degree of parallelism', 4;  
		GO  
		RECONFIGURE WITH OVERRIDE;  
		GO
	*/  