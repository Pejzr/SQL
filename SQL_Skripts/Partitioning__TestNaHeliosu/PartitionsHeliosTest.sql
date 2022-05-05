 /*
 TabPohybyZbozi -> napadl mì sloupec [IDAkce]

 Partitioning jsem provádìl na TabDokladyZbozi
 TabPohybyZbozi a TabDenik jsem nedìlal
 */



-- Doporuèoval bych dávat partyšny na not null sloupce, v pøípadì null sloupcù se hodnoty s null pøidají k první partyšnì
		CREATE PARTITION FUNCTION
			[pf_PartitionByObdobi__TabDokladyZbozi] (int)
			AS RANGE RIGHT FOR VALUES
			(
				10, 20, 30, 40, 50, 60, 70
			);
		GO

/*
1, 3, 4, 6,
22, 24, 
38, 39,
40, 42, 47, 49,
52, 53, 56, 57,
60, 61, 62, 64, 65
*/

-- Filegroupy musí být již vytvoøeny pøed pøiøazením do schématu, jinak pøíkaz vyhodí chybu
		CREATE PARTITION SCHEME [ps_PartitionByObdobi__TabDokladyZbozi]
			AS PARTITION [pf_PartitionByObdobi__TabDokladyZbozi]
			TO (
			[FGone], [FGtwo], [FGthree], [FGfour],
			[FGfive], [FGsixth], [FGseven], [FGeight],
			[FGnine]
			);
		GO


-- Vytvoøil jsem script s cizími klíèi na tabulce TabDokladyZbozi vèetnì kódu na jejich vytvoøení a smazání a výsledky uložil do master.dbo.FK_TabDokladyZbozi
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
--INTO master.dbo.FK_TabDokladyZbozi
FROM sys.foreign_keys AS f  
INNER JOIN sys.foreign_key_columns AS fc   
	ON f.object_id = fc.constraint_object_id   
WHERE f.referenced_object_id = OBJECT_ID('dbo.TabDokladyZbozi');



-- Následnì jsem projel cursorem pøíkazy na odebrání constraintù a execnul je

--DECLARE @name VARCHAR(50)
DECLARE @cmd VARCHAR(1000)

DECLARE db_cursor CURSOR FOR 
select drop_constraint_command 
from master.dbo.FK_TabDokladyZbozi

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @cmd  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	  --set @cmd = 'ALTER DATABASE ' + @name + ' SET AUTO_SHRINK OFF;'
	  exec (@cmd)
	  print @cmd + char(13) + char(10) + 'PROVEDENO' + char(13) + char(10) + char(13) + char(10)

      FETCH NEXT FROM db_cursor INTO @cmd
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 


-- Tyto 2 constraints musely být odebrány ruènì, u FK__Tabx_BalikobotVZasilkyDoklady__IdDoklad cursor vyhodil chybu a skoncil

/*
Msg 3728, Level 16, State 1, Line 17
'FK__Tabx_BalikobotVZasilkyDoklady__IdD' is not a constraint.
Msg 3727, Level 16, State 0, Line 17
Could not drop constraint. See previous errors.
*/

ALTER TABLE dbo.TabDokladyZbozi_EXT DROP CONSTRAINT FK__TabDokladyZbozi_EXT___Vendys_IDPrijemky
ALTER TABLE dbo.Tabx_BalikobotVZasilkyDoklady DROP CONSTRAINT FK__Tabx_BalikobotVZasilkyDoklady__IdDoklad

GO

ALTER TABLE [dbo].[TabDokladyZbozi] drop  CONSTRAINT [PK__TabDokladyZbozi__ID]
drop index PK__TabDokladyZbozi__ID ON dbo.TabDokladyZbozi

-- Pred vytvorenim clustered indexu musíme v pøípadì dalších FileGroup pro nì vytvoøit ndf soubory

/*
Msg 622, Level 16, State 3, Line 103
The filegroup "FGone" has no files assigned to it. Tables, indexes, text columns, ntext columns, and image columns cannot be populated on this filegroup until a file is added.
The statement has been terminated.

Completion time: 2022-03-07T16:16:16.3845088+01:00
*/


ALTER DATABASE Inuvio001
ADD FILE (NAME = Inuvio001,FILENAME = 'C:\FileGroups_Mssql\Inuvio001.ndf')
TO FILEGROUP FGone
GO



ALTER DATABASE Inuvio001
ADD FILE (NAME = FG2Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG2Inuvio001.ndf')
TO FILEGROUP [FGtwo]
GO



ALTER DATABASE Inuvio001
ADD FILE (NAME = FG3Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG3Inuvio001.ndf')
TO FILEGROUP [FGthree]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG4Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG4Inuvio001.ndf')
TO FILEGROUP [FGfour]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG5Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG5Inuvio001.ndf')
TO FILEGROUP [FGfive]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG6Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG6Inuvio001.ndf')
TO FILEGROUP [FGsixth]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG7Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG7Inuvio001.ndf')
TO FILEGROUP [FGseven]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG8Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG8Inuvio001.ndf')
TO FILEGROUP [FGeight]
GO


ALTER DATABASE Inuvio001
ADD FILE (NAME = FG9Inuvio001,FILENAME = 'C:\FileGroups_Mssql\FG9Inuvio001.ndf')
TO FILEGROUP [FGnine]
GO

-- Následnì se podíváme na soubory ve FileGroupách pro databázi

sp_helpfile


-- Pøi zkoušce pøidání unique constraint
ALTER TABLE [dbo].[TabDokladyZbozi] ADD  CONSTRAINT [UQ__TabDokladyZbozi__ID__DUZP] UNIQUE NONCLUSTERED 
(
	DUZP, ID
)

/*
Msg 1908, Level 16, State 1, Line 8
Column 'Obdobi' is partitioning column of the index 'UQ__TabDokladyZbozi__ID__DUZP'. Partition columns for a unique index must be a subset of the index key.
Msg 1750, Level 16, State 1, Line 8
Could not create constraint or index. See previous errors.
*/


-- Pokud chci vytvoøit unique clustered index musím pøidat Období, bez nìj se sice clustered index vytvoøí, ale bez unique

		drop index CLD__IX__TabDokladyZbozi__ID ON dbo.TabDokladyZbozi
		CREATE unique CLUSTERED INDEX CLD__IX__TabDokladyZbozi__ID ON dbo.TabDokladyZbozi
		(
			ID ASC,
			Obdobi ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF,
		  ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ps_PartitionByObdobi__TabDokladyZbozi] ([Obdobi])
		GO


-- Pøi vytvoøení primárního klíèe, musím zaøadit do primárního klíèe také období
Alter Table dbo.TabDokladyZbozi
Add Constraint PK__TabDokladyZbozi__ID__PK
Primary Key (ID)

/*
Msg 1908, Level 16, State 1, Line 1
Column 'Obdobi' is partitioning column of the index 'PK__TabDokladyZbozi__ID__PK'. Partition columns for a unique index must be a subset of the index key.
Msg 1750, Level 16, State 1, Line 1
Could not create constraint or index. See previous errors.
*/



-- Po pøidání sloupce Obdobi už to projde
Alter Table dbo.TabDokladyZbozi
Add Constraint PK__TabDokladyZbozi__ID__Obdobi
Primary Key (ID, Obdobi)

--Alter Table dbo.TabDokladyZbozi
--drop Constraint PK__TabDokladyZbozi__ID

  --select count(*) FROM [Inuvio001].[dbo].[TabDokladyZbozi] where IDSklad is null

  --select Obdobi, count(*) FROM [Inuvio001].[dbo].[TabDokladyZbozi] group by Obdobi
  --select IDSklad, count(*) FROM [Inuvio001].[dbo].[TabDokladyZbozi] group by IDSklad
  --select DruhPohybuZbo, count(*) FROM [Inuvio001].[dbo].[TabDokladyZbozi] group by DruhPohybuZbo


-- Obnova cizích klíèù

 ALTER TABLE dbo.Tabx_BalikobotZasilky WITH CHECK ADD  CONSTRAINT FK__Tabx_BalikobotZasilky__IdDokladyZbozi FOREIGN KEY(IdDokladyZbozi) REFERENCES dbo.TabDokladyZbozi (ID)

 -- Nelze vytvoøit, protože ID už není primární klíè, primární klíè je ID, Obdobi

/*
Msg 1776, Level 16, State 0, Line 15
There are no primary or candidate keys in the referenced table 'dbo.TabDokladyZbozi' that match the referencing column list in the foreign key 'FK__Tabx_BalikobotZasilky__IdDokladyZbozi'.
Msg 1750, Level 16, State 1, Line 15
Could not create constraint or index. See previous errors.
*/

-- Po pøidání sloupce Obdobi do cizího klíèe
  ALTER TABLE dbo.Tabx_BalikobotZasilky WITH CHECK ADD  CONSTRAINT FK__Tabx_BalikobotZasilky__IdDokladyZbozi FOREIGN KEY(IdDokladyZbozi) REFERENCES dbo.TabDokladyZbozi (ID, Obdobi)

  -- Nelze vytvoøit z dùvodu odlišného poètu sloupcù

/*
Msg 8139, Level 16, State 0, Line 15
Number of referencing columns in foreign key differs from number of referenced columns, table 'dbo.Tabx_BalikobotZasilky'.
*/

-- Nelze øešit ani vytvoøením unikántích klíèù, protože to naráží na stejný problém jako primární klíè, musí zde být sloupce ID a Obdobi