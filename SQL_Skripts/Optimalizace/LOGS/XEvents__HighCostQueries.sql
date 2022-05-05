----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--											VYTVORENI EXTENDED EVENTY NA LOGOVANI NAROCNYCH DOTAZU														--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			LOGUJE PRIKAZY DELSI NEZ 10 MICROSEKUND, KTERE NEJSOU SPOUSTENY PRES MANAGEMENT STUDIO A SQL AGENTA
----------------------------------------------------------------------------------------------------------------------------------------------------------
	CREATE EVENT SESSION [MPE__HighCostQueries] ON SERVER 
	ADD EVENT sqlserver.rpc_completed(SET collect_statement=(0)
		ACTION(sqlserver.client_app_name,sqlserver.database_name,sqlserver.sql_text,sqlserver.username)
		WHERE ([package0].[greater_than_equal_uint64]([duration],(10000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%Management%Studio%'))),
	ADD EVENT sqlserver.sp_statement_completed(SET collect_statement=(0)
		ACTION(sqlserver.client_app_name,sqlserver.database_name,sqlserver.sql_text,sqlserver.username)
		WHERE ([package0].[greater_than_equal_int64]([duration],(10000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%Management%Studio%'))),
	ADD EVENT sqlserver.sql_batch_completed(
		ACTION(sqlserver.client_app_name,sqlserver.database_name,sqlserver.sql_text,sqlserver.username)
		WHERE ([package0].[greater_than_equal_uint64]([duration],(10000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%Management%Studio%'))),
	ADD EVENT sqlserver.sql_statement_completed(SET collect_statement=(0)
		ACTION(sqlserver.client_app_name,sqlserver.database_name,sqlserver.sql_text,sqlserver.username)
		WHERE ([package0].[greater_than_equal_int64]([duration],(10000)) AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%Management%Studio%') AND NOT [sqlserver].[like_i_sql_unicode_string]([sqlserver].[client_app_name],N'%SQLAgent%')))
	ADD TARGET package0.event_file(SET filename=N'MPE__HighCostQueries')
	WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
	GO