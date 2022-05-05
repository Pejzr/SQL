----------------------------------------------------------------------------------------------------------------------------------------------------------
--																																						--
--																	   PARTITIONING																		--
--																																						--
--																																						--
--																SKRIPTY, VYSVETLENI ATD.																--
--																																						--
--																																						--
----------------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			TABULKA A DATABAZE NA KTERE JSEM PRAKTIKOVAL PARTITIONING
----------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT * FROM [AdventureWorks2017].[Sales].[SalesOrderHeader]



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			SKRIPT NA VYTVORENI PARTITIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------

		USE AdventureWorks2017
		GO

		--	NEJPRVE VYTVORIT PARTITION FUNKCI
		--	ZDE SPECIFIKUJEME DATOVY TYP SLOUPCE ROZDELENI, HRANICNI HODNOTU ROZDELENI -> RANGE (LEFT, RIGHT) A HODNOTY NA KTERYCH SE TABULKA ROZDELUJE
		CREATE PARTITION FUNCTION
			[pf_PartitionByYear] (DATETIME)
			AS RANGE RIGHT FOR VALUES
			(
				'2011-01-01', '2012-01-01', '2013-01-01', '2014-01-01'
			);
		GO

		--	DALE VYTVORIME SCHEMA NA TETO FUNKCI
		--	ZDE VOLIME BUD TUTO CAST POKUD CHCEME VSECHNA DATA DAT DO STEJNE FILEGROUPY
		CREATE PARTITION SCHEME [ps_PartitionByYear]
			AS PARTITION [pf_PartitionByYear]
			ALL TO ([PRIMARY]);
		GO

		--	NEBO TUTO CAST, KDYZ CHCEME RODELIT DATA DO RUZNYCH FILEGROUP

		CREATE PARTITION SCHEME [ps_PartitionByYear]
			AS PARTITION [pf_PartitionByYear]
			TO (
			[PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY],
			[PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY],
			[PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY],
			[PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY]
			);
		GO

		-- PRO APLIKACI PARTITIONINGU JE TREBA ODSTRANIT CLUSTERED INDEX A ZNOVU HO VYTVORIT -> !!! POZOR, JE POTREBA ODSTRANIT KLIC NA VSECH TABULKACH, KDE JE JAKO OBSAZEN V CIZIM KLICI
		CREATE CLUSTERED INDEX [IXe__SALESORDERID] ON SALES.SALESORDERHEADER
		(
			SALESORDERID ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF,
		  ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ps_PartitionByYear] ([OrderDate])
		GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			PARTITION TABULKA A POCET RADKU V JEDNOTLIVYCH PARTITIONS
--			INDEXY NA PARTITIONED TABULCE
----------------------------------------------------------------------------------------------------------------------------------------------------------

		select b.name, a.partition_number, a.rows, a.*
		from sys.partitions a with (nolock)
		inner join sys.objects b on a.object_id = b.object_id
		where a.object_id = 1922105888

		--select OBJECT_ID(N'AdventureWorks2017.[Sales].[SalesOrderHeader]') as obj_id

		select c.name, a.partition_number, a.rows, a.*, c.*
		from sys.partitions a with (nolock)
		inner join sys.indexes c on a.object_id = c.object_id and a.index_id = c.index_id
		where a.object_id = 1922105888




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			VYPIS VSECH PARTITION FUNKCI A SCHEMAT
----------------------------------------------------------------------------------------------------------------------------------------------------------

		SELECT * FROM sys.partition_functions
		SELECT * FROM sys.partition_schemes




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			VYPIS VSECH PARTITION TABULEK V DATABAZI
----------------------------------------------------------------------------------------------------------------------------------------------------------

		select distinct t.name
		from sys.partitions p
		inner join sys.tables t
		on p.object_id = t.object_id
		where p.partition_number <> 1




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			PRIDANI DALSI PARTITION
----------------------------------------------------------------------------------------------------------------------------------------------------------

		ALTER PARTITION SCHEME ps_PartitionByYear  
		NEXT USED [PRIMARY];

		ALTER PARTITION FUNCTION pf_PartitionByYear ()  
		SPLIT RANGE ('2014-06-01');  




----------------------------------------------------------------------------------------------------------------------------------------------------------
--			ODEBRANI PARTITION
----------------------------------------------------------------------------------------------------------------------------------------------------------

		ALTER PARTITION FUNCTION pf_PartitionByYear ()  
		MERGE RANGE ('2013-06-01');  



----------------------------------------------------------------------------------------------------------------------------------------------------------
--			VYPIS HRANICNICH HODNOT
----------------------------------------------------------------------------------------------------------------------------------------------------------

		SELECT 
			t.name AS [Table], 
			i.name AS [Index], 
			p.partition_number,
			f.name,
			r.boundary_id, 
			r.value AS [Boundary Value]   

		FROM sys.tables AS t  
		JOIN sys.indexes AS i  
			ON t.object_id = i.object_id  
		JOIN sys.partitions AS p
			ON i.object_id = p.object_id AND i.index_id = p.index_id   
		JOIN  sys.partition_schemes AS s   
			ON i.data_space_id = s.data_space_id  
		JOIN sys.partition_functions AS f   
			ON s.function_id = f.function_id  
		LEFT JOIN sys.partition_range_values AS r   
			ON f.function_id = r.function_id and r.boundary_id = p.partition_number 	
			
		WHERE i.type <= 1 AND t.name = 'SalesOrderHeader'		
		ORDER BY p.partition_number ASC;