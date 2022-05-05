 ALTER PROCEDURE [dbo].[Hp_checkforeginkeybeforedelete] @TABULKA   NVARCHAR(128),
                                                       --TABULKA, ZE KTERE CHCI MAZAT
                                                       @WHERE     NVARCHAR(max),
                                                       --PODMINKA, KTERE RADKY SMAZAT
                                                       @NVYSLEDEK INT out,
                                                       @CVYSLEDEK NVARCHAR(max)
out
AS
    DECLARE @CMD NVARCHAR(max)
    DECLARE @CONSTRAINT NVARCHAR(128)
    DECLARE @PARENTTAB NVARCHAR(128)
    DECLARE @PARENTCOL NVARCHAR(128)
    DECLARE @REFERENCEDTAB NVARCHAR(128)
    DECLARE @REFERENCEDCOL NVARCHAR(128)
    DECLARE @JOIN NVARCHAR(max)
    DECLARE @NROWCOUNT INT

    SET @CVYSLEDEK = ''

    IF @WHERE = ''
      SET @WHERE = ' 1 = 1 '

    IF Object_id(@TABULKA) IS NULL
        OR Objectpropertyex(Object_id(@TABULKA), 'ISTABLE') <> 1
      BEGIN
          SELECT @NVYSLEDEK = 2,
                 @CVYSLEDEK = 'TABULKA ' + Isnull(@TABULKA, '')
                              + ' NEEXISTUJE'

          RETURN
      END

    SET @CMD = N'SET PARSEONLY ON  SET NOEXEC ON '
               + 'SELECT * FROM ' + @TABULKA + ' WHERE ' + @WHERE
               + ' SET NOEXEC OFF SET PARSEONLY OFF '
  --KONTROLUJE SYNTAXI, NIKOLIV OBJEKTY

  BEGIN try
      EXEC (@CMD)
  END try

  BEGIN catch
      SELECT @NVYSLEDEK = 3,
             @CVYSLEDEK = 'ERROR ' + CONVERT(NVARCHAR(10), @@ERROR)
                          + ',  ' + LEFT(Error_message(), 160)

      RETURN
  END catch


    DECLARE cur CURSOR FOR
     
	 SELECT Object_name(constraint_object_id) AS CONSTRAINTY,
             Object_name(FK.parent_object_id)     PARENT,
             Object_name(FK.referenced_object_id) REFERENCED
      FROM   sys.foreign_key_columns FK	  
	  INNER JOIN sys.foreign_keys AS fc   
      ON fc.object_id = FK.constraint_object_id      
	  WHERE  FK.referenced_object_id = Object_id(@TABULKA) and delete_referential_action = 0
      ORDER  BY 1


    OPEN cur

    SET @NVYSLEDEK = 0

    WHILE 1 = 1
      BEGIN
          FETCH cur INTO @CONSTRAINT, @PARENTTAB, @REFERENCEDTAB

          IF @@FETCH_STATUS <> 0
            BREAK

          SET @PARENTCOL = ''
          SET @REFERENCEDCOL = ''
          SET @JOIN = ' ON '

          SELECT @JOIN = @JOIN + ' PARENTTAB.' + SC1.NAME + ' = REFTAB.'
                         + SC2.NAME + ' AND'
          FROM   sys.foreign_key_columns FK
                 JOIN sys.columns SC1
                   ON FK.parent_object_id = SC1.object_id
                      AND FK.parent_column_id = SC1.column_id
                 JOIN sys.columns SC2
                   ON FK.referenced_object_id = SC2.object_id
                      AND FK.referenced_column_id = SC2.column_id
          WHERE  FK.referenced_object_id = Object_id(@REFERENCEDTAB)
                 AND Object_name(constraint_object_id) = @CONSTRAINT

          SET @CMD = 'SELECT @NROWCOUNT = COUNT(1) FROM '
                     + @PARENTTAB + ' PARENTTAB JOIN ( SELECT * FROM '
                     + @REFERENCEDTAB + ' WHERE ' + @WHERE + ') REFTAB '
                     + LEFT(@JOIN, Len(@JOIN) - 3)

          EXEC Sp_executesql
            @CMD,
            N'@NROWCOUNT INT OUT',
            @NROWCOUNT out

          IF @NROWCOUNT > 0
            SELECT @NVYSLEDEK = 1,
                   @CVYSLEDEK = @CVYSLEDEK + @PARENTTAB + ', '
      END

    IF @NVYSLEDEK = 1
      SELECT @CVYSLEDEK = LEFT(@CVYSLEDEK, Len(@CVYSLEDEK) - 1)

    CLOSE cur

    DEALLOCATE cur  