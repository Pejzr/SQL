DECLARE	@DATABASE_NAME VARCHAR(100)	-- deklarace prom�nn� pro jm�na datab�z� v kurzoru
DECLARE @DIFF_MONTHS_ACCESS INT		-- deklarece prom�nn� pro ulo�en� rozd�lu mezi dne�n�m datem a datem posledn�ho p��stupu do DB v m�s�c�ch
DECLARE @SQL VARCHAR(1000)			-- deklarace pro p��kaz SQL, do

DECLARE AUTOCLOSE_DB_CURSOR cursor for

SELECT [name] FROM sys.databases where [database_id] > 4	-- na�teme si v�echny datab�ze krom� syst�mov�ch

open AUTOCLOSE_DB_CURSOR

fetch next from AUTOCLOSE_DB_CURSOR into @DATABASE_NAME

WHILE @@FETCH_STATUS = 0

begin
	/*
	set @filename = (@path + @SH_name + '.mdf')
	set @filename_log = (@path + @SH_name + '.ldf')

	EXEC master.sys.xp_copy_file 
    @backup_filename,
	@filename;

	EXEC master.sys.xp_copy_file 
    @backup_filename_log,
	@filename_log;

	print 'datab�ze ' + @SH_name + ' zkop�rov�na'
	*/

	SET @SQL = 'SELECT TOP(1) ACCESS FROM '+ @DATABASE_NAME +' LastAccess order by Id desc'

	SET @DIFF_MONTHS_ACCESS = (select DATEDIFF(MONTH, (convert(date ,'2021-01-05 20:35:50.630')), CONVERT(DATE, @SQL)))


	/*	BUDE POT�EBA UD�LAT TO T�MTO P��KAZEM, PROTO�E TAKTO MOHU UD�LAT USE "prom�nn�", NORM�LN� TO NEJDE, STEJN� TAK NEMOHU P�I�ADIT EXEC DO PROM�NN�
	 exec('
		declare @CMD varchar(1000) =  (SELECT TOP(1) ACCESS FROM master.dbo.LastAccess order by Id desc)
		print @CMD
		print ''select getdate()''
		set @CMD = (select getdate())
		print @CMD
	 ')
	*/

	fetch next from AUTOCLOSE_DB_CURSOR into @DATABASE_NAME;
end

close AUTOCLOSE_DB_CURSOR

deallocate AUTOCLOSE_DB_CURSOR


