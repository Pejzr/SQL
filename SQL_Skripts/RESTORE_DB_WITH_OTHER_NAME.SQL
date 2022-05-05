----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--																				--
--														OBNOVENI DATABAZE S JINYM JMENEM																--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




--	Zjistime, jak se jmenuji soubory .mdf a .ldf

	RESTORE FILELISTONLY FROM DISK='c:\backup\your.bak'


--	Na základì pøechoziho výsledku vyplnime jmena za MOVE (napr.: MOVE 'Skolici' -> MOVE 'Inuvio001')
RESTORE DATABASE SH01  
   FROM DISK = 'C:\DBS\VZ.bak'
   WITH
   MOVE 'Skolici' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.mdf', -- Nastavíme, kam se má databáze pøesunout
   MOVE 'Skolici_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.ldf';  -- Nastavíme, kam se má pøesunout transakèní log
 
