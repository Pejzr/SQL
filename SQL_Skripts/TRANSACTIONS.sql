----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--															KONTROLA SQL SERVERU																		--
--																																						--
--																																						--
--											SCRIPT NA VYBER OTEVRENYCH TRANSAKCI VCETNE JEJICH KODU														--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




	SELECT
	  GETDATE() as AKTULANI_DATUM_CAS,
	  DATEDIFF(SECOND, transaction_begin_time, GETDATE()) AS TRANSAKCE_BEZI_SEKUND,
	  st.session_id AS SESSION_ID,
	  txt.text AS SQL_PRIKAZ,
	  at.transaction_begin_time AS SPUSTENI_TRANSAKCE,
	  *
	FROM
	  sys.dm_tran_active_transactions at
	  INNER JOIN sys.dm_tran_session_transactions st ON st.transaction_id = at.transaction_id
	  LEFT OUTER JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
	  LEFT OUTER JOIN sys.dm_exec_connections conn ON conn.session_id = sess.session_id
		OUTER APPLY sys.dm_exec_sql_text(conn.most_recent_sql_handle)  AS txt
	ORDER BY
	  TRANSAKCE_BEZI_SEKUND DESC;




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			DALSI PRIKAZY NA ZJISTENI OTEVRENYCH TRANSAKCI
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT @@TRANCOUNT AS OpenTransactions;

	-- Prikaz vypisuje vysledky do Messages
	DBCC OPENTRAN;

	SELECT * FROM sys.sysprocesses WHERE open_tran = 1;