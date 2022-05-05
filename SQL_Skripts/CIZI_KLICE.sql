----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																																						--
--															CIZ� KL��E V SQL SERVERU																	--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			1.
--			VYP͊E CIZ� KL��E JIN�CH TABULEK, KTER� SE ODKAZUJ� NA TABULKU
--			JI�MI SLOVY, OBJEKTY KTER� V TABULKE D�LAJ� "ZAM�EN�" HODNOTY
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
--			STEJN� KL��E JAKO V BODU 1. + SKRIPT NA CREATE A DROP KL��E
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
--			STEJN� KL��E JAKO V BODU 1., TENTOKR�T POMOC� SYST�MOV� PROCEDURY
----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	sp_fkeys TabDokladyZbozi




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			4.
--			CIZ� KL��E, KTER� SE Z TABULKY NAOPAK ODKAZUJ� NA JIN�, LZE JE ZOBRAZIT I V SSMS
--			D�LAJ� TEDY "Z�MKY" NA HODNOT�CH V JIN�CH TABULK�CH
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT 
		OBJECT_NAME(parent_object_id) AS [FK Table],
		name AS [Foreign Key],
		OBJECT_NAME(referenced_object_id) AS [PK Table]
	FROM sys.foreign_keys
	WHERE parent_object_id = OBJECT_ID('TabDokladyZbozi');




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			5.
--			VYTVO�EN� P��KAZ� NA DROP A CREATE CIZ�CH KL��� ODKAZUJ�C�CH NA KONKR�TN� TABULKU -> POT�EBA VYPLNIT N�ZEV TABULKY
--			V�ECHNY HODNOTY ULO�ENY V TABULCE FK_DropConstraints V DATAB�ZI MASTER
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
	WHERE f.referenced_object_id = OBJECT_ID('dbo.TABULKA');	-- <- POT�EBA VYPLNIT TABULKU




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			6.
--			SMAZ�N� CIZ�CH KL��� ODKAZUJ�C�CH NA KONKR�TN� TABULKU ULO�EN�CH Z P��KAZU 5
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
--			VYTVO�EN� CIZ�CH KL��� ODKAZUJ�C�CH NA KONKR�TN� TABULKU ULO�EN�CH Z P��KAZU 5
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