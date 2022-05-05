/*
use CTAudit
alter database CTAudit set single_user with rollback immediate

use master

drop database CTAudit
GO
*/

create database CTAudit
GO

USE CTAudit
create table Employee_Main (
	id int identity(1,1) primary key,
	FirstName varchar(20),
	Lastname varchar(20)
)


--	Naplníme tabulku daty, ještì pøedtím, než na ni pustíme Change Tracking

Insert into Employee_Main
values 
	('AA', 'BB'),
	('CC', 'DD'),
	('EE', 'FF')

USE master
GO

--	Zapnutí Change Trackingu na databázi a na tabulce

ALTER DATABASE CTAudit
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)


USE CTAudit
GO

ALTER TABLE Employee_Main
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON)
GO


--	Naplníme tabulku dalšími daty, nyní je už Change Tracking zapnutý

Insert into Employee_Main
values 
	('XX', 'XX'),
	('YY', 'YY'),
	('ZZ', 'ZZ')


--	Udìláme select abychom vidìli co Change Tracking zaznamenal

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION



--	Nyní udìláme update 2 øádkù, jeden byl vložen pøed zapnutím Change Tracking, druhý po zapnutí

update Employee_Main
set FirstName = 'ABCD'
where FirstName = 'AA'

update Employee_Main
set FirstName = 'XYZ'
where FirstName = 'XX'



--	Opìt udìláme select a vidíme, že u øádku, který byl vložen po zapnutí, je stále pøíznak I, u øádku, který byl vložen pøed zapnutím je U

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION



--	Nyní udìláme delete

delete from Employee_Main
where FirstName = 'ABCD'



--	Po selectu vidíme pøíznak D

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
LEFT JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION