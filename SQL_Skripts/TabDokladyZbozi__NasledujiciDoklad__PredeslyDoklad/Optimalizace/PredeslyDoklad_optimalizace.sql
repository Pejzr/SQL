
select 

(CAST(CASE
WHEN EXISTS(SELECT 1 As PocetVazeb FROM TabZalFak  WHERE IDReal = TabDokladyZbozi.Id AND IDZal IS NOT NULL)
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb FROM TabDokladyZbozi WHERE StornoDoklad = TabDokladyZbozi.Id)
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb FROM TabDokladyZbozi WHERE NavaznyDoklad = TabDokladyZbozi.Id)
THEN 1
WHEN EXISTS(SELECT 1 AS PocetVazeb
              FROM TabDosleObjNavazTxt02
             WHERE IDNavazDok=TabDokladyZbozi.ID)
THEN 1
WHEN EXISTS(SELECT 1 AS PocetVazeb
              FROM TabDosleObjNavazDok02
             WHERE IDNavazDok=TabDokladyZbozi.ID)
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb
              FROM TabPohybyZbozi  AS SRC
              JOIN TabOZTxtPol     AS DST ON SRC.IDCiloveTxtPol = DST.ID
              JOIN TabDokladyZbozi AS SH  ON SH.ID = SRC.IDDoklad
             WHERE DST.IDDoklad = TabDokladyZbozi.Id
             -- vychazi z aktualniho clanku
               AND SH.PoradoveCislo >=0)
             -- neni to stinova hlavicka
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb
              FROM TabOZTxtPol AS SRC
              JOIN TabOZTxtPol AS DST ON SRC.IDCiloveTxtPol = DST.ID
             WHERE DST.IDDoklad = TabDokladyZbozi.Id)
             -- vychazi z aktualniho clanku
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb
              FROM TabPohybyZbozi  AS SRC
              JOIN TabPohybyZbozi  AS DST ON SRC.ID = DST.IDOldPolozka
              JOIN TabDokladyZbozi AS SH  ON SH.ID = SRC.IDDoklad
             WHERE DST.IDDoklad = TabDokladyZbozi.Id
             -- vychazi z aktualniho clanku
               AND DST.IDOldDoklad IS NULL
             -- neni to dokladovy prevod
               AND SRC.IDCiloveTxtPol IS NULL)
             -- neni to skonto
THEN 1
WHEN EXISTS(SELECT 1 As PocetVazeb
              FROM TabOZTxtPol AS SRC
              JOIN TabOZTxtPol AS DST ON SRC.ID = DST.IDOldPolozka
             WHERE DST.IDDoklad = TabDokladyZbozi.Id
             -- vychazi z aktualniho clanku
               AND DST.IDOldDoklad IS NULL
             -- neni to dokladovy prevod
               AND SRC.IDCiloveTxtPol IS NULL)
             -- neni to skonto
THEN 1
ELSE 0 END AS BIT)) as PredeslyDoklad

FROM   [tabdokladyzbozi]  

OPTION (RECOMPILE)


