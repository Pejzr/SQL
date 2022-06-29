

/****** Object:  StoredProcedure [dbo].[hp_VratPorCisKHDoklad]    Script Date: 20.06.2022 10:45:29 ******/
SET ansi_nulls ON

go

SET quoted_identifier ON

go

ALTER PROC [dbo].[Hp_vratporciskhdoklad] @IdKontrHlaDPH INT,
                                         @IdDenik       INT,
                                         @IdObdobiDPH   INT,
                                         @PorCisKV      NVARCHAR(60) output,
                                         @Chyba         NVARCHAR(5) output,
                                         @RezimDK       BIT=0
AS
    SET nocount ON

    DECLARE @IdObdobi INT, @Sbornik NVARCHAR(3), @CisloDokladu INT, @StavKraceniPK TINYINT, @IdDenikPK INT

    SELECT @IdObdobi = idobdobi,
           @Sbornik = sbornik,
           @CisloDokladu = cislodokladu,
           @StavKraceniPK = stavkracenipk,
           @IdDenikPK = iddenikpk
    FROM   tabdenik
    WHERE  id = @IdDenik

    DECLARE @PocetPorCisKV INT

    SET @Chyba=''
    SET @PorCisKV=''

    SELECT @PorCisKV = parovaciznak
    FROM   tabdenik
    WHERE  id = @IdDenik

    IF @PorCisKV <> ''
      RETURN

    IF @StavKraceniPK > 1 AND @IdDenikPK IS NOT NULL
      SELECT @IdObdobi = idobdobi,
             @Sbornik = sbornik,
             @CisloDokladu = cislodokladu
      FROM   tabdenik
      WHERE  id = @IdDenikPK


	  SELECT TabDenik.Id, tabdenik.porciskv, TabDenik.ParovaciZnak
				INTO   #poradovaCisla1
				FROM   tabdenik
					JOIN tabcisuctdef					ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
																tabcisuctdef.cisloucet = tabdenik.danovyucet

					JOIN tabcastikhcisuct				ON      tabcastikhcisuct.cisloucet = tabdenik.danovyucet
					JOIN tabkontrhladphcasti			ON      tabkontrhladphcasti.id = tabcastikhcisuct.idkontrhladphcast

				WHERE	tabdenik.idobdobi = @IdObdobi												AND
						tabdenik.sbornik = @Sbornik													AND
						tabdenik.cislodokladu = @CisloDokladu										AND
						tabdenik.idobdobidph = @IdObdobiDPH											AND
						tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH							AND
						tabcisuctdef.mistoplneni IN ( 1, 3, 4 )										AND
						( tabcisuctdef.isokodzeme = N'CZ' OR tabcisuctdef.isokodzeme IS NULL )		AND
						tabdenik.porciskv <> ''														AND
						tabdenik.id <> @IdDenik





	SELECT TabDenik.Id, tabdenik.porciskv, TabDenik.ParovaciZnak
					INTO   #poradovaCisla2
					FROM   tabdenik
					JOIN tabcisuctdef					ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
															    tabcisuctdef.cisloucet = tabdenik.danovyucet

                    JOIN tabcastikhdanklice             ON      tabcastikhdanklice.iddanovyklic = tabdenik.iddanovyklic
					JOIN tabvdanklicsazbadph            ON      tabvdanklicsazbadph.iddanklic = tabdenik.iddanovyklic
					JOIN tabsazbydph	                ON		tabsazbydph.id = tabvdanklicsazbadph.idsazbadph
					JOIN tabkontrhladphcasti            ON		tabkontrhladphcasti.id = tabcastikhdanklice.idkontrhladphcast
				
				WHERE	tabdenik.idobdobi = @IdObdobi							AND
						tabdenik.sbornik = @Sbornik								AND
						tabdenik.cislodokladu = @CisloDokladu					AND
						tabdenik.idobdobidph = @IdObdobiDPH						AND
				        tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH		AND
						tabcisuctdef.mistoplneni IN ( 1, 3, 4 )					AND
						tabsazbydph.isokodzeme = N'CZ'							AND
						tabdenik.porciskv <> ''									AND
						tabdenik.id <> @IdDenik





	IF @RezimDK = 0
	  
	  SET @PocetPorCisKV = (select COUNT(*) from #poradovaCisla1 GROUP BY porciskv)
      
	  /*
	  SET @PocetPorCisKV=
	  (
		SELECT	Count(*)
		FROM   (
				SELECT tabdenik.porciskv 
				FROM   tabdenik
					JOIN tabcisuctdef					ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
																tabcisuctdef.cisloucet = tabdenik.danovyucet

					JOIN tabcastikhcisuct				ON      tabcastikhcisuct.cisloucet = tabdenik.danovyucet
					JOIN tabkontrhladphcasti			ON      tabkontrhladphcasti.id = tabcastikhcisuct.idkontrhladphcast

				WHERE	tabdenik.idobdobi = @IdObdobi												AND
						tabdenik.sbornik = @Sbornik													AND
						tabdenik.cislodokladu = @CisloDokladu										AND
						tabdenik.idobdobidph = @IdObdobiDPH											AND
						tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH							AND
						tabcisuctdef.mistoplneni IN ( 1, 3, 4 )										AND
						( tabcisuctdef.isokodzeme = N'CZ' OR tabcisuctdef.isokodzeme IS NULL )		AND
						tabdenik.porciskv <> ''														AND
						tabdenik.id <> @IdDenik
				GROUP  BY tabdenik.porciskv
			   ) AS T
	  )
	  */

	ELSE

	  SET @PocetPorCisKV = (SELECT Count(*) from #poradovaCisla2 GROUP  BY porciskv)

	  /*
      SET @PocetPorCisKV=
	  (
		SELECT Count(*)
		FROM   (
				SELECT tabdenik.porciskv
                FROM   tabdenik
					JOIN tabcisuctdef					ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
															    tabcisuctdef.cisloucet = tabdenik.danovyucet

                    JOIN tabcastikhdanklice             ON      tabcastikhdanklice.iddanovyklic = tabdenik.iddanovyklic
					JOIN tabvdanklicsazbadph            ON      tabvdanklicsazbadph.iddanklic = tabdenik.iddanovyklic
					JOIN tabsazbydph	                ON		tabsazbydph.id = tabvdanklicsazbadph.idsazbadph
					JOIN tabkontrhladphcasti            ON		tabkontrhladphcasti.id = tabcastikhdanklice.idkontrhladphcast
				
				WHERE	tabdenik.idobdobi = @IdObdobi							AND
						tabdenik.sbornik = @Sbornik								AND
						tabdenik.cislodokladu = @CisloDokladu					AND
						tabdenik.idobdobidph = @IdObdobiDPH						AND
				        tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH		AND
						tabcisuctdef.mistoplneni IN ( 1, 3, 4 )					AND
						tabsazbydph.isokodzeme = N'CZ'							AND
						tabdenik.porciskv <> ''									AND
						tabdenik.id <> @IdDenik
				GROUP  BY tabdenik.porciskv
			   ) AS T
		)
		*/

    
	
	IF @PocetPorCisKV = 1
      BEGIN
          IF @RezimDK = 0
		    SELECT TOP 1 @PorCisKV = porciskv from #poradovaCisla1

			/*
            SELECT TOP 1 @PorCisKV = tabdenik.porciskv
            FROM	 tabdenik
				JOIN tabcisuctdef					 ON			tabcisuctdef.idobdobi = tabdenik.idobdobi AND
																tabcisuctdef.cisloucet = tabdenik.danovyucet

                JOIN tabcastikhcisuct			     ON			tabcastikhcisuct.cisloucet = tabdenik.danovyucet
                JOIN tabkontrhladphcasti             ON			tabkontrhladphcasti.id = tabcastikhcisuct.idkontrhladphcast

            WHERE  tabdenik.idobdobi = @IdObdobi											AND
                   tabdenik.sbornik = @Sbornik												AND
                   tabdenik.cislodokladu = @CisloDokladu									AND
                   tabdenik.idobdobidph = @IdObdobiDPH										AND
                   tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH						AND
                   tabcisuctdef.mistoplneni IN ( 1, 3, 4 )									AND
                   (tabcisuctdef.isokodzeme = N'CZ' OR tabcisuctdef.isokodzeme IS NULL)		AND
                   tabdenik.porciskv <> ''													AND
                   tabdenik.id <> @IdDenik
			*/
          
		  ELSE
			SELECT TOP 1 @PorCisKV = porciskv from #poradovaCisla2

			/*
            SELECT TOP 1 @PorCisKV = tabdenik.porciskv
            FROM		tabdenik
                JOIN	tabcisuctdef            ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
														tabcisuctdef.cisloucet = tabdenik.danovyucet

                JOIN tabcastikhdanklice         ON		tabcastikhdanklice.iddanovyklic = tabdenik.iddanovyklic
                JOIN tabvdanklicsazbadph        ON		tabvdanklicsazbadph.iddanklic = tabdenik.iddanovyklic
                JOIN tabsazbydph                ON		tabsazbydph.id = tabvdanklicsazbadph.idsazbadph
                JOIN tabkontrhladphcasti        ON		tabkontrhladphcasti.id = tabcastikhdanklice.idkontrhladphcast
            
			WHERE  tabdenik.idobdobi = @IdObdobi									AND
                   tabdenik.sbornik = @Sbornik										AND
                   tabdenik.cislodokladu = @CisloDokladu							AND
                   tabdenik.idobdobidph = @IdObdobiDPH								AND
                   tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH				AND
                   tabcisuctdef.mistoplneni IN ( 1, 3, 4 )							AND
                   tabsazbydph.isokodzeme = N'CZ'									AND
                   tabdenik.porciskv <> ''											AND
                   tabdenik.id <> @IdDenik

			*/
      END
    
	ELSE
      BEGIN
          SET @PocetPorCisKV =
		  (
		   SELECT Count(*)
           FROM   (
				   SELECT porciskv
                   FROM   tabdenik
                   WHERE  idobdobi = @IdObdobi				AND
						  sbornik = @Sbornik				AND
                          cislodokladu = @CisloDokladu		AND
                          porciskv <> ''
                   GROUP  BY porciskv
				  ) AS T
		  )

          IF @PocetPorCisKV > 1
            BEGIN
                SET @Chyba=N'63873'
            END
          ELSE
            BEGIN
                IF @PocetPorCisKV = 1
                  SELECT TOP 1 @PorCisKV = porciskv
                  FROM   tabdenik
                  WHERE  idobdobi = @IdObdobi
                         AND sbornik = @Sbornik
                         AND cislodokladu = @CisloDokladu
                         AND porciskv <> ''
                ELSE
                  BEGIN
                      IF @RezimDK = 0
					    SET @PocetPorCisKV = (SELECT COUNT(*) FROM #poradovaCisla1 pc WHERE pc.ParovaciZnak <> N'Err' GROUP BY pc.ParovaciZnak)

						/*
                        SET @PocetPorCisKV=(SELECT Count(*)
                                            FROM   (
													SELECT tabdenik.parovaciznak
                                                    FROM   tabdenik
														JOIN tabcisuctdef			  ON      tabcisuctdef.idobdobi = tabdenik.idobdobi      AND
																							  tabcisuctdef.cisloucet = tabdenik.danovyucet

														JOIN tabcastikhcisuct         ON      tabcastikhcisuct.cisloucet = tabdenik.danovyucet
														JOIN tabkontrhladphcasti      ON      tabkontrhladphcasti.id = tabcastikhcisuct.idkontrhladphcast
											
													WHERE	tabdenik.idobdobi = @IdObdobi											AND
															tabdenik.sbornik = @Sbornik												AND
															tabdenik.cislodokladu = @CisloDokladu									AND
															tabdenik.idobdobidph = @IdObdobiDPH										AND
															tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH						AND
															tabcisuctdef.mistoplneni IN ( 1, 3, 4 )									AND
															(tabcisuctdef.isokodzeme = N'CZ' OR tabcisuctdef.isokodzeme IS NULL)	AND
															tabdenik.parovaciznak <> ''												AND
															tabdenik.parovaciznak <> N'Err'											AND
															tabdenik.id <> @IdDenik
													
													GROUP  BY tabdenik.parovaciznak
												   ) AS T
											)
						*/
          
					ELSE
					    SET @PocetPorCisKV=(SELECT Count(*) from #poradovaCisla2 pc where pc.ParovaciZnak <> N'Err'	GROUP BY pc.ParovaciZnak)

						/*
						SET @PocetPorCisKV=(SELECT Count(*)
											FROM   (
													SELECT tabdenik.parovaciznak
													FROM   tabdenik
														JOIN tabcisuctdef				ON          tabcisuctdef.idobdobi = tabdenik.idobdobi	AND
																									tabcisuctdef.cisloucet = tabdenik.danovyucet

														JOIN tabcastikhdanklice			ON          tabcastikhdanklice.iddanovyklic = tabdenik.iddanovyklic
														JOIN tabvdanklicsazbadph		ON          tabvdanklicsazbadph.iddanklic = tabdenik.iddanovyklic
														JOIN tabsazbydph				ON			tabsazbydph.id = tabvdanklicsazbadph.idsazbadph
														JOIN tabkontrhladphcasti		ON			tabkontrhladphcasti.id = tabcastikhdanklice.idkontrhladphcast
								 
													WHERE  tabdenik.idobdobi = @IdObdobi							AND
														tabdenik.sbornik = @Sbornik									AND 
														tabdenik.cislodokladu = @CisloDokladu						AND 
														tabdenik.idobdobidph = @IdObdobiDPH							AND
														tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH          AND 
														tabcisuctdef.mistoplneni IN ( 1, 3, 4 )						AND
														tabsazbydph.isokodzeme = N'CZ'								AND 
														tabdenik.parovaciznak <> ''									AND
														tabdenik.parovaciznak <> N'Err'								AND
														tabdenik.id <> @IdDenik
								
													GROUP  BY tabdenik.parovaciznak
												   ) AS T
											)
						*/

          IF @PocetPorCisKV = 1
          BEGIN
			IF @RezimDK = 0
				SELECT TOP 1 @PorCisKV = ParovaciZnak from #poradovaCisla1 pc WHERE pc.ParovaciZnak <> N'Err'

				/*
				SELECT TOP 1 @PorCisKV = tabdenik.parovaciznak
				FROM   tabdenik
					JOIN tabcisuctdef		ON		tabcisuctdef.idobdobi = tabdenik.idobdobi	AND
													tabcisuctdef.cisloucet = tabdenik.danovyucet
					JOIN tabcastikhcisuct    ON	 tabcastikhcisuct.cisloucet = tabdenik.danovyucet
					JOIN tabkontrhladphcasti	ON tabkontrhladphcasti.id = tabcastikhcisuct.idkontrhladphcast
				
				WHERE	tabdenik.idobdobi = @IdObdobi													AND
          				tabdenik.sbornik = @Sbornik														AND
						tabdenik.cislodokladu = @CisloDokladu											AND
						tabdenik.idobdobidph = @IdObdobiDPH												AND
				        tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH								AND
						tabcisuctdef.mistoplneni IN ( 1, 3, 4 )											AND
						(tabcisuctdef.isokodzeme = N'CZ' OR tabcisuctdef.isokodzeme IS NULL)			AND
						tabdenik.parovaciznak <> ''														AND
						tabdenik.parovaciznak <> N'Err'													AND
						tabdenik.id <> @IdDenik

				*/

			ELSE
				SELECT TOP 1 @PorCisKV = ParovaciZnak from #poradovaCisla2 pc where pc.ParovaciZnak <> N'Err'

				/*
				SELECT TOP 1 @PorCisKV = tabdenik.parovaciznak
				FROM   tabdenik
					JOIN tabcisuctdef				ON		tabcisuctdef.idobdobi = tabdenik.idobdobi AND
															tabcisuctdef.cisloucet = tabdenik.danovyucet

					JOIN tabcastikhdanklice			ON		tabcastikhdanklice.iddanovyklic = tabdenik.iddanovyklic
					JOIN tabvdanklicsazbadph        ON      tabvdanklicsazbadph.iddanklic = tabdenik.iddanovyklic
					JOIN tabsazbydph				ON		tabsazbydph.id = tabvdanklicsazbadph.idsazbadph
					JOIN tabkontrhladphcasti        ON		tabkontrhladphcasti.id =     tabcastikhdanklice.idkontrhladphcast
				
				WHERE  tabdenik.idobdobi = @IdObdobi				AND
           tabdenik.sbornik = @Sbornik								AND
           tabdenik.cislodokladu = @CisloDokladu					AND
           tabdenik.idobdobidph = @IdObdobiDPH						AND
           tabkontrhladphcasti.idkontrhladph = @IdKontrHlaDPH		AND
           tabcisuctdef.mistoplneni IN ( 1, 3, 4 )					AND
           tabsazbydph.isokodzeme = N'CZ'							AND
           tabdenik.parovaciznak <> ''								AND
           tabdenik.parovaciznak <> N'Err'							AND
           tabdenik.id <> @IdDenik									
		   */

          END
          
		  
		  ELSE
          BEGIN
			IF (SELECT Count(*)
				FROM   (
						SELECT parovaciznak
						FROM   tabdenik
						WHERE  idobdobi = @IdObdobi				AND
							   sbornik = @Sbornik				AND
							   cislodokladu = @CisloDokladu		AND
							   parovaciznak <> ''				AND
							   parovaciznak <> N'Err'
						GROUP  BY parovaciznak
					   ) AS T
				) > 1
          
			BEGIN
				SET @Chyba=N'62586'
			END
			ELSE
				SELECT TOP 1 @PorCisKV = parovaciznak
				FROM   tabdenik
				WHERE  idobdobi = @IdObdobi					AND
					   sbornik = @Sbornik					AND
					   cislodokladu = @CisloDokladu			AND
				       parovaciznak <> ''					AND
					   parovaciznak <> N'Err'				
			END
          END
        END
      END

    SET @PorCisKV=Isnull(@PorCisKV, '')  