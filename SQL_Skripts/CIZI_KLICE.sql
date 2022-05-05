----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																																						--
--															CIZÍ KLÍÈE V SQL SERVERU																	--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			1.
--			VYPÍŠE CIZÍ KLÍÈE JINÝCH TABULEK, KTERÉ SE ODKAZUJÍ NA TABULKU
--			JIÝMI SLOVY, OBJEKTY KTERÉ V TABULKE DÌLAJÍ "ZAMÈENÉ" HODNOTY
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT
		OBJECT_NAME(referenced_object_id) as 'Referenced Object',
		OBJECT_NAME(parent_object_id) as 'Referencing Object',
		COL_NAME(parent_object_id, parent_column_id) as 'Referencing Column Name',
		OBJECT_NAME(constraint_object_id) 'Constraint Name'
	FROM sys.foreign_key_columns
	WHERE OBJECT_NAME(referenced_object_id) = 'TabDokladyZbozi'




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			2.
--			STEJNÉ KLÍÈE JAKO V BODU 1. + SKRIPT NA CREATE A DROP KLÍÈE
----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	SELECT   
		f.name AS foreign_key_name  
		,OBJECT_NAME(f.parent_object_id) AS table_name  
		,COL_NAME(fc.parent_object_id, fc.parent_column_id) AS constraint_column_name  
		,OBJECT_NAME (f.referenced_object_id) AS referenced_object  
		,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS referenced_column_name
		,CONCAT(
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id),	' WITH CHECK ADD  CONSTRAINT ', f.name,
			' FOREIGN KEY(', COL_NAME(fc.parent_object_id, fc.parent_column_id), ') REFERENCES ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME (f.referenced_object_id),
			' (', COL_NAME(fc.referenced_object_id, fc.referenced_column_id), ')', CHAR(13) + CHAR(10), ' GO', CHAR(13) + CHAR(10), CHAR(13) + CHAR(10),
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id), ' CHECK CONSTRAINT ', f.name, CHAR(13) + CHAR(10), ' GO'
		) as create_constraint_command
		,CONCAT(
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id), ' DROP CONSTRAINT ', f.name, CHAR(13) + CHAR(10), ' GO'
		) AS drop_constraint_command
		,is_disabled  
		,delete_referential_action_desc  
		,update_referential_action_desc  
	FROM sys.foreign_keys AS f  
	INNER JOIN sys.foreign_key_columns AS fc   
		ON f.object_id = fc.constraint_object_id   
	WHERE f.referenced_object_id = OBJECT_ID('dbo.TabDokladyZbozi');




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			3.
--			STEJNÉ KLÍÈE JAKO V BODU 1., TENTOKRÁT POMOCÍ SYSTÉMOVÉ PROCEDURY
----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	sp_fkeys TabDokladyZbozi




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			4.
--			CIZÍ KLÍÈE, KTERÉ SE Z TABULKY NAOPAK ODKAZUJÍ NA JINÉ, LZE JE ZOBRAZIT I V SSMS
--			DÌLAJÍ TEDY "ZÁMKY" NA HODNOTÁCH V JINÝCH TABULKÁCH
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
		OBJECT_NAME(parent_object_id) AS [FK Table],
		name AS [Foreign Key],
		OBJECT_NAME(referenced_object_id) AS [PK Table]
	FROM sys.foreign_keys
	WHERE parent_object_id = OBJECT_ID('TabDokladyZbozi');




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			5.
--			VYTVOØENÍ PØÍKAZÙ NA DROP A CREATE CIZÍCH KLÍÈÙ ODKAZUJÍCÍCH NA KONKRÉTNÍ TABULKU -> POTØEBA VYPLNIT NÁZEV TABULKY
--			VŠECHNY HODNOTY ULOŽENY V TABULCE FK_DropConstraints V DATABÁZI MASTER
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DROP TABLE IF EXISTS master.[dbo].[FK_DropConstraints];
	GO	


	SELECT   
		f.name AS foreign_key_name  
		,OBJECT_NAME(f.parent_object_id) AS table_name  
		,COL_NAME(fc.parent_object_id, fc.parent_column_id) AS constraint_column_name  
		,OBJECT_NAME (f.referenced_object_id) AS referenced_object  
		,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS referenced_column_name
		,CONCAT(
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id),	' WITH CHECK ADD  CONSTRAINT ', f.name,
			' FOREIGN KEY(', COL_NAME(fc.parent_object_id, fc.parent_column_id), ') REFERENCES ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME (f.referenced_object_id),
			' (', COL_NAME(fc.referenced_object_id, fc.referenced_column_id), ')', CHAR(13) + CHAR(10), CHAR(13) + CHAR(10), CHAR(13) + CHAR(10),
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id), ' CHECK CONSTRAINT ', f.name, CHAR(13) + CHAR(10)
		) as create_constraint_command
		,CONCAT(
			'ALTER TABLE ', SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id), ' DROP CONSTRAINT ', f.name, CHAR(13) + CHAR(10)
		) AS drop_constraint_command
		,is_disabled  
		,delete_referential_action_desc  
		,update_referential_action_desc
	INTO master.dbo.FK_DropConstraints
	FROM sys.foreign_keys AS f  
	INNER JOIN sys.foreign_key_columns AS fc   
		ON f.object_id = fc.constraint_object_id   
	WHERE f.referenced_object_id = OBJECT_ID('dbo.TABULKA');	-- <- POTØEBA VYPLNIT TABULKU




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			6.
--			SMAZÁNÍ CIZÍCH KLÍÈÙ ODKAZUJÍCÍCH NA KONKRÉTNÍ TABULKU ULOŽENÝCH Z PØÍKAZU 5
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @cmd VARCHAR(1000)

	DECLARE db_cursor CURSOR FOR 
	select drop_constraint_command 
	from master.dbo.FK_DropConstraints

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @cmd  

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		  exec (@cmd)
		  print @cmd + 'PROVEDENO' + char(13) + char(10) + char(13) + char(10)

		  FETCH NEXT FROM db_cursor INTO @cmd
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 
	GO



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			7.
--			VYTVOØENÍ CIZÍCH KLÍÈÙ ODKAZUJÍCÍCH NA KONKRÉTNÍ TABULKU ULOŽENÝCH Z PØÍKAZU 5
----------------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @cmd VARCHAR(1000)

	DECLARE db_cursor CURSOR FOR 
	select create_constraint_command 
	from master.dbo.FK_DropConstraints

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @cmd  

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		  exec (@cmd)
		  print @cmd + 'PROVEDENO' + char(13) + char(10) + char(13) + char(10)

		  FETCH NEXT FROM db_cursor INTO @cmd
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 