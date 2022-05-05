USE inuvio001

SELECT ( Isnull((SELECT TOP 1 D.sazbadph
                 FROM   (SELECT Z.druhsazbydph,
                                Z.isokodzeme,
                                Z.platnostod,
                                Z.platnostdo,
                                Z.vstupvystup,
                                Z.prednastaveno,
                                Z.idkmenzbozi,
                                NULL AS SkupZbo,
                                1    AS NaKmeni
                         FROM   tabsazbydphzbo AS Z
                         WHERE  Z.idkmenzbozi = tabkmenzbozi.id
                         UNION
                         SELECT S.druhsazbydph,
                                S.isokodzeme,
                                S.platnostod,
                                S.platnostdo,
                                S.vstupvystup,
                                S.prednastaveno,
                                NULL,
                                S.skupzbo,
                                0
                         FROM   tabsazbydphsku AS S
                         WHERE  S.skupzbo = tabkmenzbozi.skupzbo) AS I
                        JOIN tabsazbydph AS D
                          ON D.druhsazbydph = I.druhsazbydph
                             AND D.isokodzeme = I.isokodzeme
                             AND Isnull(D.platnostod, '19000101 00:00:00.000')
                                 <=
                                 Getdate
                                 ()
                             AND Isnull(D.platnostdo, '99991231 23:59:59.997')
                                 >=
                                 Getdate
                                 ()
                             AND Isnull(D.datukonceni, '99991231 23:59:59.997')
                                 >=
                                 Getdate()
                 WHERE  Isnull(I.platnostod, '19000101 00:00:00.000') <= Getdate
                        ()
                        AND Isnull(I.platnostdo, '99991231 23:59:59.997') >=
                            Getdate()
                        AND I.isokodzeme IN(SELECT isokod
                                            FROM   tabzeme
                                            WHERE  vlastni = 1)
                        AND I.vstupvystup IN( 0, 2 )
                 ORDER  BY I.nakmeni DESC,
                           I.prednastaveno DESC), tabkmenzbozi.sazbadphvstup) )
FROM   tabkmenzbozi  