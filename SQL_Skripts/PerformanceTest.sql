 CREATE PROCEDURE dbo.Hp_benchmarktest
AS
    SET nocount ON

    DECLARE @X INT = 200000 --pocet zaznamu v tabulce,  default 200000    
    DECLARE @PocetDotazu INT = 50 --pocet dotazu do tabulky, default 100    
    DECLARE @XMAX INT
    DECLARE @NAHODNEID INT
    DECLARE @ErrorMessage NVARCHAR(1000)

    IF Object_id(N'tempdb..##BenchmarkTestBezi') IS NOT NULL
      BEGIN
          RAISERROR(N'Benchamrk test uz je spusteny',16,1)

          RETURN
      END
    ELSE
      CREATE TABLE ##benchmarktestbezi
        (
           id INT
        )

  BEGIN try
      IF Object_id('dbo.TestPerformanceTable') IS NOT NULL
        DROP TABLE dbo.testperformancetable

      IF Object_id('dbo.TestPerformanceTableLog') IS NOT NULL
        DROP TABLE dbo.testperformancetablelog

      CREATE TABLE dbo.testperformancetable
        (
           id     INT PRIMARY KEY,
           akce   INT,
           zprava NVARCHAR(100),
           datum  DATETIME
        )

      CREATE TABLE dbo.testperformancetablelog
        (
           id          INT PRIMARY KEY IDENTITY(1, 1),
           akce        NVARCHAR(100),
           starttime   DATETIME2 DEFAULT Sysdatetime(),
           endtime     DATETIME2,
           cassec AS Datediff(second, starttime, endtime),
           standardsec INT,
           casprocent AS Format(1.0 * Datediff(millisecond, starttime, endtime)
                                /
                                (
                                standardsec * 1000 ),
                            'p')
        )

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT 'Naplneni tabulky '
             + Format(@X, '# ### ###') + ' zaznamu',
             13

      SET @XMAX = @X

      WHILE @X >= 0
        BEGIN
            INSERT INTO testperformancetable
                        (id,
                         akce,
                         zprava,
                         datum)
            SELECT @XMAX - @X,
                   @X%100,
                   Replicate(Char(Rand() * 25 + 65), Rand() * 10 + 1),
                   Sysdatetime()

            SET @X = @X - 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT 'Aktualizace vsech radku ',
             13

      SELECT @X = Min(id)
      FROM   testperformancetable

      SELECT @XMAX = Max(id)
      FROM   testperformancetable

      WHILE @X <= @XMAX
        BEGIN
            UPDATE testperformancetable
            SET    akce = akce + 100,
                   zprava = zprava + ' + ' + zprava,
                   datum = Sysdatetime()
            WHERE  id = @X

            SET @X = @X + 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT Format(@PocetDotazu * 100, '# ### ###')
             + ' dotazu pres clusterovany index a insert do temp tabulky ',
             6

      SET @X = 0

      SELECT @XMAX = Max(id)
      FROM   testperformancetable

      WHILE @X <= @PocetDotazu * 100
        BEGIN
            IF Object_id('tempdb..#testy') IS NOT NULL
              DROP TABLE #testy

            SET @NAHODNEID = Rand() * @XMAX

            SELECT *
            INTO   #testy
            FROM   testperformancetable
            WHERE  id BETWEEN @NAHODNEID - 1000 AND @NAHODNEID

            SET @X = @X + 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT Format(@PocetDotazu, '# ### ###')
             + ' dotazu pres neindexovany sloupec a insert do temp tabulky ',
             9

      SET @X = 0

      WHILE @X <= @PocetDotazu
        BEGIN
            IF Object_id('tempdb..#testy2') IS NOT NULL
              DROP TABLE #testy2

            SELECT *
            INTO   #testy2
            FROM   testperformancetable
            WHERE  zprava LIKE '%' + Char(Rand()*25+65) + '%'

            SET @X = @X + 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      DECLARE @tabulka TABLE
        (
           id     INT,
           akce   INT,
           zprava NVARCHAR(100),
           datum  DATETIME
        )

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT Format(@PocetDotazu * 100, '# ### ###')
             +
  ' dotazu pres clusterovany index a insert do promenne typu tabulka ',
             14

      SET @X = 0

      SELECT @XMAX = Max(id)
      FROM   testperformancetable

      WHILE @X <= @PocetDotazu * 100
        BEGIN
            SET @NAHODNEID = Rand() * @XMAX

            DELETE @tabulka

            INSERT INTO @tabulka
                        (id,
                         akce,
                         zprava,
                         datum)
            SELECT *
            FROM   testperformancetable
            WHERE  id BETWEEN @NAHODNEID - 1000 AND @NAHODNEID

            SET @X = @X + 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT Format(@PocetDotazu, '# ### ###')
             +
  ' dotazu pres neindexovany sloupec a insert do promenne typu tabulka ',
             10

      SET @X = 0

      WHILE @X <= @PocetDotazu
        BEGIN
            DELETE @tabulka

            INSERT INTO @tabulka
            SELECT *
            FROM   testperformancetable
            WHERE  zprava LIKE '%' + Char(Rand()*25+65) + '%'

            SET @X = @X + 1
        END

      UPDATE testperformancetablelog
      SET    endtime = Sysdatetime()
      WHERE  id = (SELECT Max(id)
                   FROM   testperformancetablelog)

      INSERT INTO testperformancetablelog
                  (akce,
                   standardsec)
      SELECT Format(@PocetDotazu, '# ### ###')
             +
' Vyuziti poddotazu pres neindexovany sloupec a insert do promenne typu tabulka '
       ,
53

    SET @X = 0

    WHILE @X <= @PocetDotazu
      BEGIN
          DELETE @tabulka

          INSERT INTO @tabulka
          SELECT *
          FROM   testperformancetable
          WHERE  akce IN (SELECT akce
                          FROM   testperformancetable
                          WHERE  zprava LIKE '%' + Char(Rand()*25+65) + '%')
                 AND akce IN (SELECT akce
                              FROM   testperformancetable
                              WHERE  zprava LIKE '%' + Char(Rand()*25+65) + '%')
                 AND akce IN (SELECT akce
                              FROM   testperformancetable
                              WHERE  zprava LIKE '%' + Char(Rand()*25+65) + '%')

          SET @X = @X + 1

          PRINT CONVERT(NVARCHAR(50), Getdate(), 120)

          PRINT @X
      END

    UPDATE testperformancetablelog
    SET    endtime = Sysdatetime()
    WHERE  id = (SELECT Max(id)
                 FROM   testperformancetablelog)

    INSERT INTO testperformancetablelog
                (akce,
                 starttime,
                 endtime)
    SELECT Replicate('-', 50),
           NULL,
           NULL

    INSERT INTO testperformancetablelog
                (akce,
                 starttime,
                 endtime,
                 standardsec)
    SELECT 'Celkovy cas',
           Min(starttime),
           Max(endtime),
           Sum(standardsec)
    FROM   testperformancetablelog

    SELECT *
    FROM   testperformancetablelog
END try

  BEGIN catch
      SET @ErrorMessage = Isnull(Error_message(), 'Neznama chyba')

      RAISERROR(@ErrorMessage,16,1)
  END catch

    DROP TABLE ##benchmarktestbezi  