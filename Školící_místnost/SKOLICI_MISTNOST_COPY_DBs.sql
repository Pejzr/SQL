USE [msdb]
GO

/****** Object:  Job [Rozkopirovani_EVD00]    Script Date: 22. 4. 2022 14:53:35 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 22. 4. 2022 14:53:35 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Rozkopirovani_EVD00', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Vytvoøení zálohy databáze EVD00 a následné rozkopírování databáze EVD00 na 16 samostatných databází.,', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'EDUPH\skolitel', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete_old_backup]    Script Date: 22. 4. 2022 14:53:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete_old_backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC xp_cmdshell ''del C:\DBS\VZ.BAK''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create_backup_of_VZ_DB]    Script Date: 22. 4. 2022 14:53:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create_backup_of_VZ_DB', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master;
go

BACKUP DATABASE VZ TO DISK = ''C:\DBS\VZ.BAK''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Copy_VZ_DB_to_DBS_SH01-SH16]    Script Date: 22. 4. 2022 14:53:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy_VZ_DB_to_DBS_SH01-SH16', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'RESTORE DATABASE SH01  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH01.ldf'';  
 

RESTORE DATABASE SH02  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH02.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH02.ldf'';  


RESTORE DATABASE SH03  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH03.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH03.ldf'';  


RESTORE DATABASE SH04  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH04.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH04.ldf'';  


RESTORE DATABASE SH05  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH05.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH05.ldf'';  


RESTORE DATABASE SH06  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH06.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH06.ldf'';  


RESTORE DATABASE SH07  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH07.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH07.ldf'';  


RESTORE DATABASE SH08  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH08.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH08.ldf'';  


RESTORE DATABASE SH09  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH09.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH09.ldf'';  


RESTORE DATABASE SH10  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH10.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH10.ldf'';  


RESTORE DATABASE SH11  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH11.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH11.ldf'';  


RESTORE DATABASE SH12  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH12.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH12.ldf'';  


RESTORE DATABASE SH13  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH13.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH13.ldf'';  


RESTORE DATABASE SH14  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH14.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH14.ldf'';  


RESTORE DATABASE SH15  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH15.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH15.ldf'';  


RESTORE DATABASE SH16  
   FROM DISK = ''C:\DBS\VZ.bak''
   WITH
   MOVE ''Skolici'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH16.mdf'',
   MOVE ''Skolici_log'' TO ''C:\Program Files\Microsoft SQL Server\MSSQL15.ORANGE2019\MSSQL\DATA\SH16.ldf'';', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every_Friday', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20220429, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, 
		@schedule_uid=N'7ad4dc55-c725-4844-9384-06c6c0e5e56a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


