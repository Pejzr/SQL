----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--												SMAZANI A ZNOVU NAKOPIROVANI DATABAZI VE SKOLICI MISTNOSTI												--
--																																						--
--																																						--
--							!!! PRED SPUSTENIM JE NUTNE RUCNE NAKOPIROVAT DO URCENE SLOZKY DATABAZI, ZE KTERE BUDEME TVORIT OSTATNI !!!					--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------


use master;
go

/*

	1) Nejd��ve zaktualizovat v Heliosu datab�zi ROZ
	2) Zaktualizovanou datab�zi rozkop�rovat (Ctrl+c, Ctrl+v) do slo�kz C:\DBS\ a t�m nahradit st�vaj�c� starou datab�zi ROZ
	3) spustit F5 tento skript

*/



print 'P�ipravuji odebr�n� datab�z� SH.' + CHAR(13)

/* Nejprve odstran�me datab�ze SHXX, pokud n�jakou chceme nechat zakomentujeme ��dek */
drop database SH01;
drop database SH02;
drop database SH03;
drop database SH04;
drop database SH05;
drop database SH06;
drop database SH07;
drop database SH08;
drop database SH09;
drop database SH10;
drop database SH11;
drop database SH12;
drop database SH13;
drop database SH14;
drop database SH15;
drop database SH16;

print 'Odeb�r�n� datab�z� SH dokon�eno.' + CHAR(13)
print 'P�ipravuji ulo�en� n�zv� SH do do�asn� tabulky.' + CHAR(13)


/* Ulo��me si do do�asn� tabulky #ListOfSHDBs n�zvy SH01 a� SH16 */
declare @i int = 1;

DROP TABLE IF EXISTS #ListOfSHDBs;

create table #ListOfSHDBs (
	name varchar(10)
);


while @i <= 16
	begin
		insert into #ListOfSHDBs values ('SH' + iif(@i < 10, '0' + cast(@i as varchar(2)), cast(@i as varchar(2))));
		set @i = @i + 1;
	end

print CHAR(13)
print 'Ulo�en� n�zv� SH do do�asn� tabulky dokon�eno.' + CHAR(13)
print 'P�ipravuji deklarace prom�nn�ch.' + CHAR(13)


/* Nadeklarujeme si prom�nn�, kter� budeme pot�ebovat */
declare @path varchar(100) = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\'			--	CILOVA SLOZKA, DO KTERE BUDEME KOPIROVAT
declare @SH_name varchar(10)																				--	JMENO SHXX DATABAZE
declare @filename varchar(255)																				--	CILOVY SOUBOR (SH01, ...), MENI SE DYNAMICKY V CURSORU
declare @filename_log varchar(255)																			--	CILOVY LOG SOUBOR, MENI SE DYNAMICKY V CURSORU
declare @backup_filename varchar(255) = 'C:\BACKUP\Skolici.mdf'												--	ZDROJOVY SOUBOR
declare @backup_filename_log varchar(255) = 'C:\BACKUP\Skolici.ldf'										--	ZDROJOVY LOG SOUBOR

print 'Deklarace prom�nn�ch dokon�ena.' + CHAR(13)
print 'P�ipravuji spu�t�n� kurzoru.' + CHAR(13)


/* V Cursoru rozkop�rujeme zdrojovou datab�zi do SH01 a� SH16 */
declare db_cursor cursor for

select [name] from #ListOfSHDBs -- do kurzoru na�teme n�zvy SH01 a� SH16

open db_cursor

fetch next from db_cursor into @SH_name

WHILE @@FETCH_STATUS = 0

begin
	set @filename = (@path + @SH_name + '.mdf')
	set @filename_log = (@path + @SH_name + '.ldf')

	EXEC master.sys.xp_copy_file 
    @backup_filename,
	@filename;

	EXEC master.sys.xp_copy_file 
    @backup_filename_log,
	@filename_log;

	print 'datab�ze ' + @SH_name + ' zkop�rov�na'


	fetch next from db_cursor into @SH_name;
end

close db_cursor

deallocate db_cursor

print CHAR(13)
print 'Spu�t�n� kurzoru dokon�eno.' + CHAR(13)
print 'P�ipravuji Attach datab�z�.' + CHAR(13)


/* Nyn� je�t� datab�ze p�ipoj�me (ATTACH) */
 CREATE DATABASE SH01 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH01.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH01.ldf' )
 FOR ATTACH

 CREATE DATABASE SH02 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH02.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH02.ldf' )
 FOR ATTACH

 CREATE DATABASE SH03 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH03.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH03.ldf' )
 FOR ATTACH

 CREATE DATABASE SH04 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH04.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH04.ldf' )
 FOR ATTACH

 CREATE DATABASE SH05 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH05.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH05.ldf' )
 FOR ATTACH

 CREATE DATABASE SH06 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH06.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH06.ldf' )
 FOR ATTACH

CREATE DATABASE SH07 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH07.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH07.ldf' )
 FOR ATTACH

 CREATE DATABASE SH08 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH08.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH08.ldf' )
 FOR ATTACH

 CREATE DATABASE SH09 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH09.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH09.ldf' )
 FOR ATTACH

 CREATE DATABASE SH10 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH10.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH10.ldf' )
 FOR ATTACH

 CREATE DATABASE SH11 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH11.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH11.ldf' )
 FOR ATTACH

 CREATE DATABASE SH12 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH12.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH12.ldf' )
 FOR ATTACH

 CREATE DATABASE SH13 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH13.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH13.ldf' )
 FOR ATTACH

 CREATE DATABASE SH14 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH14.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH14.ldf' )
 FOR ATTACH

 CREATE DATABASE SH15 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH15.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH15.ldf' )
 FOR ATTACH

 CREATE DATABASE SH16 ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH16.mdf' )
, ( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MPSERVER\MSSQL\DATA\SH16.ldf' )
 FOR ATTACH


print 'Attach datab�z� dokon�en.' + CHAR(13) + CHAR(13)


go


use master;
go

/* Kontrola Login�, pokud n�kter� neexistuj�, budou vytvo�eny */

	declare @SH_number int = 1
	declare @SH_Login varchar(20) = 'SH_user01'
	declare @cmd varchar(200);

	PRINT 'Test existence login�:' + CHAR(13)

	while @SH_number <= 16
		BEGIN
			IF EXISTS (SELECT name  
				FROM master.sys.server_principals
				WHERE name = @SH_Login)

				BEGIN
					print 'Login ' + @SH_Login + ' existuje.'
				END
			ELSE
				BEGIN
					print 'Login ' + @SH_Login + ' neexistuje. Vytv���m...'
					set @cmd = 'CREATE LOGIN ' + @SH_Login + ' WITH PASSWORD = ''SkoliciSH' + RIGHT('00' + cast(@SH_number as varchar(2)),2) + '''';
					print @cmd
					exec (@cmd)
					print 'Login ' + @SH_Login + ' vytvo�en.' + CHAR(13)
				END

			SET @SH_number = @SH_number + 1
			SET @SH_Login = CONCAT('SH_user', RIGHT('00' + cast(@SH_number as varchar(2)),2))
		END

		PRINT CHAR(13) + CHAR(13) + 'LOGINY zkontrolov�ny/vyto�eny.' + CHAR(13) + CHAR(13) + CHAR(13)
	GO

/*
-- Ru�n� vytvo�en�/odebr�n� login�:

USE master;

CREATE LOGIN SH_user01 WITH PASSWORD = 'SkoliciSH01' -- m�sto SH_user01 doplnit LOGIN, kter� chceme vytvo�it a m�sto SkoliciSH01 doplnit heslo, kter� pro LOGIN chceme
DROP LOGIN SH_user01 -- m�sto SH_user01 doplnit LOGIN, kter� chceme odebrat
go
*/


/* Kontrola u�ivatel� v nult� datab�zi, pokud n�kte�� neexistuj�, budou vytvo�eni */

	USE iNuvio001;

	declare @SH_number int = 1
	declare @SH_User varchar(20) = 'user01'
	declare @cmd varchar(100);

	PRINT 'Test existence u�ivatel�:' + CHAR(13)

	while @SH_number <= 16
		BEGIN
			IF EXISTS (SELECT name  
				FROM sys.database_principals
				WHERE name = @SH_User)

				BEGIN
					print 'User ' + @SH_User + ' existuje'
				END
			ELSE
				BEGIN
					print 'User ' + @SH_User + ' neexistuje. Vytv���m...'
					set @cmd = 'CREATE USER ' + @SH_User + ' FOR LOGIN SH_user' + RIGHT('00' + cast(@SH_number as varchar(2)),2) 
					+ CHAR(13) + 'ALTER ROLE db_owner ADD MEMBER user' + RIGHT('00' + cast(@SH_number as varchar(2)),2);
					print @cmd
					exec (@cmd)
					print 'User ' + @SH_User + ' vytvo�en.' + CHAR(13)
				END

			SET @SH_number = @SH_number + 1
			SET @SH_User = CONCAT('user', RIGHT('00' + cast(@SH_number as varchar(2)),2))
		END

		PRINT CHAR(13) + CHAR(13) + 'U�ivatel� zkontrolov�ni/vytvo�eni.' + CHAR(13) + CHAR(13) + CHAR(13)
	GO

/*
-- Ru�n� vytvo�en�/odebr�n� u�ivatel�:

use iNuvio001;

create user user01 for login SH_user01 -- m�sto user01 doplnit jm�no u�ivatale, m�sto SH_user01 doplnit login na kter� se u�ivatel nav�e
alter role db_owner add member user01 -- m�sto user01 doplnit u�ivatele, kter�mu chceme p�i�adit db_owner roli

DROP USER user01 -- m�sto user01 doplnit u�ivatele, kter�ho chceme odebrat (!!! Pozor, LOGIN na kter� je u�ivatel nav�z�n, z�stane !!!)

go
*/


/* Vytvo�en� u�ivatel� pro jednotliv� datab�ze a loginy */

PRINT 'Vytv���m u�ivatele userXX a nastavuji pr�va db_owner pro jednotliv� datab�ze SHXX.' + CHAR(13)

use SH01;
create user user01 for login SH_user01
alter role db_owner add member user01
go

use SH02;
create user user02 for login SH_user02
alter role db_owner add member user02
go

use SH03;
create user user03 for login SH_user03
alter role db_owner add member user03
go

use SH04;
create user user04 for login SH_user04
alter role db_owner add member user04
go

use SH05;
create user user05 for login SH_user05
alter role db_owner add member user05
go

use SH06;
create user user06 for login SH_user06
alter role db_owner add member user06
go

use SH07;
create user user07 for login SH_user07
alter role db_owner add member user07
go

use SH08;
create user user08 for login SH_user08
alter role db_owner add member user08
go

use SH09;
create user user09 for login SH_user09
alter role db_owner add member user09
go

use SH10;
create user user10 for login SH_user10
alter role db_owner add member user10
go

use SH11;
create user user11 for login SH_user11
alter role db_owner add member user11
go

use SH12;
create user user12 for login SH_user12
alter role db_owner add member user12
go

use SH13;
create user user13 for login SH_user13
alter role db_owner add member user13
go

use SH14;
create user user14 for login SH_user14
alter role db_owner add member user14
go

use SH15;
create user user15 for login SH_user15
alter role db_owner add member user15
go

use SH16;
create user user16 for login SH_user16
alter role db_owner add member user16
go

PRINT 'U�ivatel� na datab�z�ch SHXX vytvo�eni s pr�vy db_owner.'

print '
------------------------------------------------------
--				!!! Skript dob�hl !!!				--
------------------------------------------------------
'
