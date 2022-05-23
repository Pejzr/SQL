----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																																						--
--															ZPÙSOBY IMPORTÙ EXCELU DO SQL SERVERU														--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------------------
--		POŽADAVKY PRO OPENROWSET A OPENDATASOURCE:
--		NAINSTALOVAT:	Microsoft Access Database Engine 2010 Redistributable
--		SPUSTIT:
/*
				sp_configure 'show advanced options', 1;
				RECONFIGURE;
				GO
				sp_configure 'Ad Hoc Distributed Queries', 1;
				RECONFIGURE;
				GO
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------




USE ImportFromExcel;
GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			1.
--			BULK INSERT - NEJVYŠŠÍ MÍRA PØIZPÙSOBENÍ
--			LZE IMPORTOVAT POUZE .CSV SOUBORY
--			STRUKTURA TABULKY UŽ MUSÍ EXISTOVAT
----------------------------------------------------------------------------------------------------------------------------------------------------------

--	Vytvoøíme tabulku TEMP_FILES, do které naimportujeme názvy souborù pro pozdìjší použití
IF OBJECT_ID('TEMPDB..#TEMP_FILES') IS NOT NULL DROP TABLE #TEMP_FILES

CREATE TABLE #TEMP_FILES
(
FileName VARCHAR(MAX),	-- jméno souboru
DEPTH VARCHAR(MAX),		-- hloubka souboru (soubor je v podsložkách)
[FILE] VARCHAR(MAX)		-- je soubor(1), není soubor(0)
)


INSERT INTO #TEMP_FILES
EXEC master.dbo.xp_DirTree 'C:\MPE_Dev\SQL\Ukázky\kvìten-porada\',1,1


select * from #TEMP_FILES


--	Odstraníme z tabulky soubory, které nejsou formátu .CSV
DELETE FROM #TEMP_FILES WHERE RIGHT(FileName,4) != '.CSV'


IF OBJECT_ID('ImportFromExcel.dbo.Politici') IS NOT NULL DROP TABLE ImportFromExcel.dbo.Politici
create table ImportFromExcel.dbo.Politici (
	-- id int identity(1,1),	BULK INSERT S IDENTITY NEUMÍ PRACOVAT A ZAHLÁSÍ ERROR
	jmeno nvarchar(255)
	,prijmeni nvarchar(255)
)


DECLARE @FILENAME VARCHAR(MAX),@SQL VARCHAR(MAX)

--	Format file je potøeba kvùli správnému formátu vkládaných dat (napø.: háèky a èárky), lze použít i xml file
 
WHILE EXISTS(SELECT * FROM #TEMP_FILES)
BEGIN
   SET @FILENAME = (SELECT TOP 1 FileName FROM #TEMP_FILES)
   SET @SQL = 'BULK INSERT  ImportFromExcel.dbo.Politici
   FROM ''C:\MPE_Dev\SQL\Ukázky\kvìten-porada\' + @FILENAME +'''
   WITH (FIRSTROW = 2,
		 FIELDTERMINATOR = '';'', 
		 ROWTERMINATOR = ''\n'', 
		 FORMATFILE = ''C:\MPE_Dev\SQL\Ukázky\kvìten-porada\format.fmt''
		);'
  
   PRINT @SQL
   EXEC(@SQL)
  
   DELETE FROM #TEMP_FILES WHERE FileName = @FILENAME
 
END


select * from ImportFromExcel.dbo.Politici

GO



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			2.
--			OPENROWSET, OPENDATASOURCE (DISTRIBUTED QUERIES)
--			STRUKTURA TABULKY NEMUSÍ EXISTOVAT
----------------------------------------------------------------------------------------------------------------------------------------------------------

USE ImportFromExcel;
GO

IF OBJECT_ID('ImportFromExcel.dbo.Politici') IS NOT NULL DROP TABLE ImportFromExcel.dbo.Politici


--	POKUD TABULKA NEEXISTUJE
SELECT * INTO ImportFromExcel.dbo.Politici
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0; Database=C:\MPE_Dev\SQL\Ukázky\kvìten-porada\Data3.xlsx', [List1$]);
GO

select * from ImportFromExcel.dbo.Politici
TRUNCATE TABLE ImportFromExcel.dbo.Politici


--	POKUD TABULKA EXISTUJE
INSERT INTO ImportFromExcel.dbo.Politici
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0; Database=C:\MPE_Dev\SQL\Ukázky\kvìten-porada\Data3.xlsx', [List1$]);
GO

select * from ImportFromExcel.dbo.Politici

GO



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			3.
--			IMPORT FLAT FILE TO SQL WIZARD
--			LZE IMPORTOVAT POUZE .CSV NEBO .TXT SOUBORY
--			NELZE IMPROTOVAT DO JIŽ EXISTUJÍCÍ TABULKY, ŠPATNÌ FORMÁTUJE TEXT
----------------------------------------------------------------------------------------------------------------------------------------------------------

--		ImportFromExcel -> Tasks -> Import Flat File...