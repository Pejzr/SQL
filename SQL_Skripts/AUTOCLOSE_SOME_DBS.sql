DECLARE	@DATABASE_NAME VARCHAR(100)	-- deklarace promìnné pro jména databází v kurzoru
DECLARE @DIFF_MONTHS_ACCESS INT		-- deklarece promìnné pro uložení rozdílu mezi dnešním datem a datem posledního pøístupu do DB v mìsících
DECLARE @SQL VARCHAR(1000)			-- deklarace pro pøíkaz SQL, do

DECLARE AUTOCLOSE_DB_CURSOR cursor for

SELECT [name] FROM sys.databases where [database_id] > 4	-- naèteme si všechny databáze kromì systémových

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

	print 'databáze ' + @SH_name + ' zkopírována'
	*/

	SET @SQL = 'SELECT TOP(1) ACCESS FROM '+ @DATABASE_NAME +' LastAccess order by Id desc'

	SET @DIFF_MONTHS_ACCESS = (select DATEDIFF(MONTH, (convert(date ,'2021-01-05 20:35:50.630')), CONVERT(DATE, @SQL)))


	/*	BUDE POTØEBA UDÌLAT TO TÍMTO PØÍKAZEM, PROTOŽE TAKTO MOHU UDÌLAT USE "promìnná", NORMÁLNÌ TO NEJDE, STEJNÌ TAK NEMOHU PØIØADIT EXEC DO PROMÌNNÉ
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


