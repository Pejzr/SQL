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


--	Napln�me tabulku daty, je�t� p�edt�m, ne� na ni pust�me Change Tracking

Insert into Employee_Main
values 
	('AA', 'BB'),
	('CC', 'DD'),
	('EE', 'FF')

USE master
GO

--	Zapnut� Change Trackingu na datab�zi a na tabulce

ALTER DATABASE CTAudit
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)


USE CTAudit
GO

ALTER TABLE Employee_Main
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON)
GO


--	Napln�me tabulku dal��mi daty, nyn� je u� Change Tracking zapnut�

Insert into Employee_Main
values 
	('XX', 'XX'),
	('YY', 'YY'),
	('ZZ', 'ZZ')


--	Ud�l�me select abychom vid�li co Change Tracking zaznamenal

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION



--	Nyn� ud�l�me update 2 ��dk�, jeden byl vlo�en p�ed zapnut�m Change Tracking, druh� po zapnut�

update Employee_Main
set FirstName = 'ABCD'
where FirstName = 'AA'

update Employee_Main
set FirstName = 'XYZ'
where FirstName = 'XX'



--	Op�t ud�l�me select a vid�me, �e u ��dku, kter� byl vlo�en po zapnut�, je st�le p��znak I, u ��dku, kter� byl vlo�en p�ed zapnut�m je U

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION



--	Nyn� ud�l�me delete

delete from Employee_Main
where FirstName = 'ABCD'



--	Po selectu vid�me p��znak D

SELECT * FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT ORDER BY SYS_CHANGE_VERSION



SELECT CT.SYS_CHANGE_VERSION, 
  CT.SYS_CHANGE_OPERATION, EM.* 
  FROM CHANGETABLE 
(CHANGES [Employee_Main],0) as CT 
LEFT JOIN [dbo].[Employee_Main] EM
ON CT.ID = EM.ID
ORDER BY SYS_CHANGE_VERSION