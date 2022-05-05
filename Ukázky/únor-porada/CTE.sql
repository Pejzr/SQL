-- set statistics time, io on


Select
 (cast(
CASE
WHEN isnull(tabdokladyzbozi.navaznydoklad,0) <> 0 THEN
  1
WHEN isnull(tabdokladyzbozi.stornodoklad,0) <> 0 THEN
  1
WHEN EXISTS
  (
         SELECT 1 AS pocetvazeb
         FROM   tabzalfak
         WHERE  idzal = tabdokladyzbozi.id) THEN
  1
WHEN EXISTS
  (
         SELECT 1 AS pocetvazeb
         FROM   tabdosleobjvazbadok02
         WHERE  iddokzbo=tabdokladyzbozi.id) THEN
  1
WHEN EXISTS
  (
         SELECT 1           AS pocetvazeb
         FROM   taboztxtpol AS dst
         JOIN   taboztxtpol AS src
         ON     src.id = dst.idoldpolozka
         WHERE  src.iddoklad = tabdokladyzbozi.id
         AND    dst.idolddoklad IS NULL
         AND    dst.idcilovetxtpol IS NULL) THEN
  1
WHEN EXISTS
  (
         SELECT 1              AS pocetvazeb
         FROM   tabpohybyzbozi AS dst
         JOIN   tabpohybyzbozi AS src
         ON     src.id = dst.idoldpolozka
         JOIN   tabdokladyzbozi AS dh
         ON     dh.id = dst.iddoklad
         WHERE  src.iddoklad = tabdokladyzbozi.id
         AND    dst.idolddoklad IS NULL
         AND    dh.poradovecislo >= 0
         AND    dst.idcilovetxtpol IS NULL) THEN
  1
WHEN EXISTS
  (
         SELECT 1              AS pocetvazeb
         FROM   tabpohybyzbozi AS dst
         JOIN   tabpohybyzbozi AS src
         ON     src.id = dst.idoldpolozka
         JOIN   tabvstin AS vst
         ON     vst.idstinpolozka = dst.id
         JOIN   tabpohybyzbozi AS dpo
         ON     dpo.id = vst.idpolozka
         JOIN   tabdokladyzbozi AS dh
         ON     dh.id = dst.iddoklad
         WHERE  src.iddoklad = tabdokladyzbozi.id
         AND    dpo.idolddoklad IS NULL
         AND    dh.poradovecislo < 0
         AND    dst.idcilovetxtpol IS NULL) THEN
  1
  ELSE 0
END
AS bit)) as NasledujiciDoklad

FROM   [tabdokladyzbozi]  

;

 with tempcte (ID, IDDoklad, poradovecislo) as (
	SELECT DST.Id, SRC.IDDoklad, DH.poradovecislo
                            FROM   tabpohybyzbozi AS DST
                                   JOIN tabpohybyzbozi AS SRC
                                     ON SRC.id = DST.idoldpolozka
                                   JOIN tabdokladyzbozi AS DH
                                     ON DH.id = DST.iddoklad
                            WHERE  DST.idolddoklad IS NULL
                                   AND DST.idcilovetxtpol IS NULL
 )
 
 
 SELECT id, ( Cast(CASE
                WHEN Isnull(tabdokladyzbozi.navaznydoklad, 0) <> 0 THEN 1
                WHEN Isnull(tabdokladyzbozi.stornodoklad, 0) <> 0 THEN 1
                WHEN EXISTS(SELECT 1 AS PocetVazeb
                            FROM   tabzalfak
                            WHERE  idzal = tabdokladyzbozi.id) THEN 1
                WHEN EXISTS(SELECT 1 AS PocetVazeb
                            FROM   tabdosleobjvazbadok02
                            WHERE  iddokzbo = tabdokladyzbozi.id) THEN 1
                WHEN EXISTS(SELECT 1 AS PocetVazeb
                            FROM   taboztxtpol
                            WHERE  id = idoldpolozka
								   AND iddoklad = tabdokladyzbozi.id
                                   AND idolddoklad IS NULL
                                   AND idcilovetxtpol IS NULL) THEN 1
                WHEN EXISTS(SELECT 1 AS PocetVazeb
                            FROM   tempcte AS SRC
                            WHERE  SRC.iddoklad = tabdokladyzbozi.id
								   AND SRC.poradovecislo >= 0) THEN 1
                WHEN EXISTS(SELECT 1 AS PocetVazeb
                            FROM   tempcte AS SRC
                                   JOIN tabvstin AS VST
                                     ON VST.idstinpolozka = SRC.id
                                   JOIN tabpohybyzbozi AS DPO
                                     ON DPO.id = VST.idpolozka

                            WHERE  SRC.iddoklad = tabdokladyzbozi.id
                                   AND SRC.poradovecislo < 0) THEN 1
                ELSE 0
              END AS BIT) ) AS NasledujiciDoklad
FROM   tabdokladyzbozi  

