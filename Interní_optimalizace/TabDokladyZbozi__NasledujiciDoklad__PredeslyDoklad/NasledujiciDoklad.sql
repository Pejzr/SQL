
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
