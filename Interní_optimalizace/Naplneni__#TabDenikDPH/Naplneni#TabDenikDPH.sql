-- vytvoreni docasne tabulky pro prehled
IF OBJECT_ID(N'tempdb..#TabDenikDPH')IS NOT NULL
BEGIN
TRUNCATE TABLE #TabDenikDPH
END
ELSE
BEGIN
CREATE TABLE dbo.#TabDenikDPH(
Id INT NULL,
ICO NVARCHAR(20) COLLATE database_default NULL,
IdObdobi INT NOT NULL,
NazevObdobi NVARCHAR(10) COLLATE database_default NOT NULL,
Sbornik NVARCHAR(3) COLLATE database_default NULL,
CisloDokladu INT NULL,
CeleCislo NVARCHAR(14) COLLATE database_default NOT NULL,
CeleCisloDlouhe NVARCHAR(11) COLLATE database_default NOT NULL,
ParovaciZnak NVARCHAR(60) COLLATE database_default NOT NULL CONSTRAINT DF__#TabDenikDPH__ParovaciZnak__54 DEFAULT '',
DatumDUZP DATETIME NULL,
DatumDoruceni DATETIME NULL,
DICOrg NVARCHAR(15) COLLATE database_default NULL,
Utvar NVARCHAR(30) COLLATE database_default NULL,
CisloZakazky NVARCHAR(15) COLLATE database_default NULL,
CisloNakladovyOkruh NVARCHAR(15) COLLATE database_default NULL,
IdVozidlo INT NULL,
CisloZam INT NULL,
CisloOrg INT NULL,
SazbaDane NUMERIC(5,2) NULL,
ZakladDane NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__ZakladDane__54 DEFAULT (0.0),
CastkaDane NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__CastkaDane__54 DEFAULT (0.0),
OdchylkaDane NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__OdchylkaDane__54 DEFAULT (0.0),
CelyNazevUcet NVARCHAR(251) COLLATE database_default NULL,
DanovyUcet NVARCHAR(30) COLLATE database_default NULL,
KodZeme NVARCHAR(3) COLLATE database_default NULL,
Seskupeno TINYINT NOT NULL CONSTRAINT DF__#TabDenikDPH__Seskupeno__54 DEFAULT 0,
VykazDPH11 INT NULL,
IdDokladyZbozi INT NULL,
IdPoklDoklad INT NULL,
IdObdobiDPH INT NULL,
Popis NVARCHAR(255) COLLATE database_default NOT NULL CONSTRAINT DF__#TabDenikDPH__Popis__54 DEFAULT '',
CisloRadku INT NULL,
CastkaDaneKracena NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__CastkaDaneKracena__54 DEFAULT (0.0),
VlastniDIC NVARCHAR(15) COLLATE database_default NULL,
Mena NVARCHAR(3) COLLATE database_default NULL,
Sluzba TINYINT NULL CONSTRAINT DF__#TabDenikDPH__Sluzba__54 DEFAULT 0,
IdDanovyKlic INT NULL,
ISOKodZeme NVARCHAR(3) COLLATE database_default NULL,
SmerPlneni TINYINT NULL,
PosledniUhrada DATETIME NULL,
PosledniPreuc NVARCHAR(20) COLLATE database_default NULL,
DelkaPorCis TINYINT NULL,
ZakladDaneEUR NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__ZakladDaneEUR__54 DEFAULT (0.0),
CastkaDaneEUR NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__CastkaDaneEUR__54 DEFAULT (0.0),
KurzCMEUR NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__KurzCMEUR__54 DEFAULT (1.0),
JednotkaCMEUR INT NOT NULL CONSTRAINT DF__#TabDenikDPH__JednotkaCMEUR__54 DEFAULT (1),
ZakladDaneHM NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__ZakladDaneHM__54 DEFAULT (0.0),
CastkaDaneHM NUMERIC(19,6) NOT NULL CONSTRAINT DF__#TabDenikDPH__CastkaDaneHM__54 DEFAULT (0.0),
DatumDUZP_D AS (DATEPART(DAY,[DatumDUZP])),
DatumDUZP_M AS (DATEPART(MONTH,[DatumDUZP])),
DatumDUZP_Y AS (DATEPART(YEAR,[DatumDUZP])),
DatumDUZP_Q AS (DATEPART(QUARTER,[DatumDUZP])),
DatumDUZP_W AS (DATEPART(WEEK,[DatumDUZP])),
DatumDUZP_X AS (CONVERT(DATETIME,CONVERT(INT,CONVERT(FLOAT,[DatumDUZP])))),
DatumDoruceni_D AS (DATEPART(DAY,[DatumDoruceni])),
DatumDoruceni_M AS (DATEPART(MONTH,[DatumDoruceni])),
DatumDoruceni_Y AS (DATEPART(YEAR,[DatumDoruceni])),
DatumDoruceni_Q AS (DATEPART(QUARTER,[DatumDoruceni])),
DatumDoruceni_W AS (DATEPART(WEEK,[DatumDoruceni])),
DatumDoruceni_X AS (CONVERT(DATETIME,CONVERT(INT,CONVERT(FLOAT,[DatumDoruceni])))),
PosledniUhrada_D AS (DATEPART(DAY,[PosledniUhrada])),
PosledniUhrada_M AS (DATEPART(MONTH,[PosledniUhrada])),
PosledniUhrada_Y AS (DATEPART(YEAR,[PosledniUhrada])),
PosledniUhrada_Q AS (DATEPART(QUARTER,[PosledniUhrada])),
PosledniUhrada_W AS (DATEPART(WEEK,[PosledniUhrada])),
PosledniUhrada_X AS (CONVERT(DATETIME,CONVERT(INT,CONVERT(FLOAT,[PosledniUhrada])))),
Cislo AS (CONVERT([nvarchar](17),isnull(replicate(N'0',case when [DelkaPorCis] IS NULL then (6) else [DelkaPorCis] end-len([CisloDokladu])),N'')+CONVERT([nvarchar](11),[CisloDokladu]))),
CONSTRAINT CK__#TabDenikDPH__Sluzba__54 CHECK(Sluzba IN(0,1,2,3,4,5)),
CONSTRAINT CK__#TabDenikDPH__DelkaPorCis__54 CHECK(DelkaPorCis IN(6,7)),
CONSTRAINT CK__#TabDenikDPH__KurzCMEUR__54 CHECK(KurzCMEUR >0),
CONSTRAINT CK__#TabDenikDPH__JednotkaCMEUR__54 CHECK(JednotkaCMEUR >0))
CREATE CLUSTERED INDEX IC__TabDenikDPH__Id ON dbo.#TabDenikDPH(Id)
CREATE INDEX IX__TabDenikDPH__CeleCislo ON dbo.#TabDenikDPH(CeleCislo)
CREATE INDEX IX__TabDenikDPH__Seskupeno ON dbo.#TabDenikDPH(Seskupeno)
END

-- dane obdobi DPH, nutno doplnit @IdObdobiDPH
-- XXX = Id z tabulky TabObdobiDPH
DECLARE @IdObdobiDPH INT
SET @IdObdobiDPH=XXX

-- vykonny kod - plneni #TabDenikDPH
SET NOCOUNT ON
DECLARE @IdObdDPH INT, @ParovaniPopis BIT, @ParovaniPZ BIT, @IdObdobi INT, @NazevObdobi NVARCHAR(10)
DECLARE @Utvar NVARCHAR(30), @CisloZakazky NVARCHAR(15), @NO NVARCHAR(15), @IdVozidlo INT, @CisloZam INT,
@Popis NVARCHAR(255), @IDDokladyZbozi INT, @IDPoklDoklad INT, @PoziceZaokr TINYINT, @UpravaPZ BIT
DECLARE @DatumOd DATETIME, @DatumDo DATETIME, @Dodatecne TINYINT, @ISOKodZeme NVARCHAR(3), @VzorEU INT, @RezimDK BIT, @Koeficient NUMERIC(19,6)
DECLARE @IdKontrDPH INT, @PorCisKV NVARCHAR(60), @ChybaKV NVARCHAR(5)
SELECT @IdObdDPH=Id, @VzorEU=VzorEU, @DatumOd=DatumOd, @DatumDo=DatumDo, @Dodatecne=NahradniDPH, @ISOKodZeme=ISOKodZeme,
@PoziceZaokr=PoziceZaokrDPH, @RezimDK=RezimDK,
@Koeficient=CASE WHEN VzorEU IN (3,4) THEN
CASE WHEN Vyrovnani=1 THEN VyrKoeficientEU/100 ELSE VyrKoeficient/100 END
ELSE
CASE WHEN Vyrovnani=1 THEN VyrKoeficientEU ELSE VyrKoeficient END
END
FROM TabObdobiDPH WHERE Id=@IdObdobiDPH
IF OBJECT_ID(N'tempdb..#TabIdObdobiDPH') IS NULL
CREATE TABLE #TabIdObdobiDPH (Id INT NOT NULL)
ELSE
TRUNCATE TABLE #TabIdObdobiDPH
INSERT #TabIdObdobiDPH (Id) VALUES(@IdObdobiDPH)
IF @VzorEU>399 AND @VzorEU<500
BEGIN
IF @Dodatecne=1
INSERT INTO #TabIdObdobiDPH (Id)
SELECT TabObdobiDPH.Id FROM TabObdobiDPH
WHERE DatumOd=@DatumOd AND DatumDo=@DatumDo AND DatumProvedeni IS NOT NULL AND NahradniDPH<2 AND
TabObdobiDPH.Id<>@IdObdobiDPH AND ISOKodZeme=@ISOKodZeme
IF @Dodatecne=2
INSERT INTO #TabIdObdobiDPH (Id)
SELECT TabObdobiDPH.Id FROM TabObdobiDPH
WHERE DatumOd=@DatumOd AND DatumDo=@DatumDo AND DatumProvedeni IS NOT NULL AND
TabObdobiDPH.Id<>@IdObdobiDPH AND ISOKodZeme=@ISOKodZeme
END
INSERT #TabDenikDPH
(ID,IdObdobi,IdObdobiDPH,NazevObdobi,CeleCislo,CeleCisloDlouhe,ParovaciZnak,CelyNazevUcet,DatumDUZP,DatumDoruceni,
Utvar,CisloZakazky,CisloNakladovyOkruh,IdVozidlo,CisloOrg,CisloZam,VykazDPH11,
SazbaDane,ZakladDane,CastkaDane,OdchylkaDane,Sbornik,CisloDokladu,
IdDokladyZbozi,IdPoklDoklad,Popis,CisloRadku,DICOrg,DanovyUcet,IdDanovyKlic,ISOKodZeme,CastkaDaneKracena,SmerPlneni,DelkaPorCis)
SELECT
TabDenik.ID,TabDenik.IdObdobi,TabDenik.IdObdobiDPH,TabObdobi.Nazev,TabDenik.CeleCislo,TabDenik.CeleCisloDlouhe,TabDenik.ParovaciZnak,
TabCisUctDef.CelyNazev,TabDenik.DatumDUZP_X,TabDenik.DatumDoruceni_X,
TabDenik.Utvar,TabDenik.CisloZakazky,TabDenik.CisloNakladovyOkruh,TabDenik.IdVozidlo,
TabDenik.CisloOrg,TabDenik.CisloZam,
CASE WHEN @RezimDK=0 THEN
(SELECT TOP 1 TabRadkyDPH.Radek FROM TabRadkyDPH
JOIN TabRadkyDPHCisUct ON TabRadkyDPHCisUct.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHCisUct.CisloUcet=TabDenik.DanovyUcet AND TabRadkyDPH.IdObdDPH=@IdObdobiDPH AND
TabDenik.IdObdobi=CASE WHEN TabRadkyDPHCisUct.IdObdobi IS NULL THEN TabDenik.IdObdobi
ELSE TabRadkyDPHCisUct.IdObdobi
END
ORDER BY Radek ASC)
ELSE
(SELECT TOP 1 TabRadkyDPH.Radek FROM TabRadkyDPH
JOIN TabRadkyDPHDanKlice ON TabRadkyDPHDanKlice.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHDanKlice.IdDanovyKlic=TabDenik.IdDanovyKlic AND TabRadkyDPH.IdObdDPH=@IdObdobiDPH
ORDER BY Radek ASC)
END,
TabDenik.SazbaDane,
ISNULL(TabDenik.ZakladDane,0),ISNULL(TabDenik.CastkaDane,0),
ISNULL(TabDenik.CastkaDane,0) - ROUND(ISNULL(TabDenik.ZakladDane,0) * TabDenik.SazbaDane / 100, @PoziceZaokr),
TabDenik.Sbornik,TabDenik.CisloDokladu,TabDenik.IdDokladyZbozi,TabDenik.IdPoklDoklad,
TabDenik.Popis,TabDenik.CisloRadku,TabDenik.DICOrg,TabDenik.DanovyUcet,TabDenik.IdDanovyKlic,TabDenik.ISOKodZeme,
CASE WHEN @RezimDK=0 THEN
CASE WHEN EXISTS(SELECT * FROM TabRadkyDPH
JOIN TabRadkyDPHCisUct ON TabRadkyDPHCisUct.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPH.NarokDPH=1 AND TabRadkyDPHCisUct.CisloUcet=TabDenik.DanovyUcet AND TabRadkyDPH.IdObdDPH=@IdObdobiDPH AND
TabDenik.IdObdobi=CASE WHEN TabRadkyDPHCisUct.IdObdobi IS NULL THEN TabDenik.IdObdobi
ELSE TabRadkyDPHCisUct.IdObdobi
END)
THEN ISNULL(TabDenik.CastkaDane,0)*@Koeficient
ELSE ISNULL(TabDenik.CastkaDane,0)
END
ELSE
CASE WHEN EXISTS(SELECT * FROM TabRadkyDPH
JOIN TabRadkyDPHDanKlice ON TabRadkyDPHDanKlice.IdRadekDPH=TabRadkyDPH.Id
JOIN TabDanoveKlice ON TabDanoveKlice.Id=TabRadkyDPHDanKlice.IdDanovyKlic
WHERE TabRadkyDPH.NarokDPH=1 AND
TabRadkyDPHDanKlice.IdDanovyKlic=TabDenik.IdDanovyKlic AND
TabRadkyDPH.IdObdDPH=@IdObdobiDPH AND
TabDanoveKlice.SmerPlneni=2 AND TabDenik.Strana=1)
THEN ISNULL(TabDenik.CastkaDane,0)
ELSE
CASE WHEN EXISTS(SELECT * FROM TabRadkyDPH
JOIN TabRadkyDPHDanKlice ON TabRadkyDPHDanKlice.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPH.NarokDPH=1 AND TabRadkyDPHDanKlice.IdDanovyKlic=TabDenik.IdDanovyKlic AND TabRadkyDPH.IdObdDPH=@IdObdobiDPH)
THEN ISNULL(TabDenik.CastkaDane,0)*@Koeficient
ELSE ISNULL(TabDenik.CastkaDane,0)
END
END
END,
CASE WHEN @RezimDK=0 THEN
TabCisUctDef.SmerPlneni
ELSE
CASE TabDanoveKlice.SmerPlneni WHEN 0 THEN 0
WHEN 1 THEN 1
WHEN 2 THEN CASE WHEN TabDenik.Strana=0 THEN 0 ELSE 1 END
WHEN 3 THEN 1
END
END, TabDenik.DelkaPorCis
FROM TabDenik WITH(INDEX=IX__TabDenik__IdObdobiDPH)
JOIN TabCisUctDef ON TabCisUctDef.IdObdobi=TabDenik.IdObdobi AND TabCisUctDef.CisloUcet=TabDenik.DanovyUcet
 LEFT OUTER JOIN TabDanoveKlice ON TabDanoveKlice.Id=TabDenik.IdDanovyKlic
JOIN TabObdobi ON TabObdobi.Id=TabDenik.IdObdobi
JOIN #TabIdObdobiDPH ON #TabIdObdobiDPH.Id=TabDenik.IdObdobiDPH
WHERE TabDenik.Zaknihovano>0
IF @VzorEU<399
BEGIN
IF @RezimDK=0
UPDATE #TabDenikDPH
SET VykazDPH11=
(SELECT MAX(TabRadkyDPH.Radek) FROM TabRadkyDPH
JOIN TabRadkyDPHCisUct ON TabRadkyDPHCisUct.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHCisUct.CisloUcet=#TabDenikDPH.DanovyUcet AND TabRadkyDPH.IdObdDPH=#TabDenikDPH.IdObdobiDPH AND
#TabDenikDPH.IdObdobi=CASE WHEN TabRadkyDPHCisUct.IdObdobi IS NULL THEN #TabDenikDPH.IdObdobi
ELSE TabRadkyDPHCisUct.IdObdobi
END)
FROM #TabDenikDPH
JOIN TabCisUctDef ON TabCisUctDef.IdObdobi=#TabDenikDPH.IdObdobi AND TabCisUctDef.CisloUcet=#TabDenikDPH.DanovyUcet
WHERE TabCisUctDef.MistoPlneni=4 AND #TabDenikDPH.SmerPlneni=0
ELSE
UPDATE #TabDenikDPH
SET VykazDPH11=
(SELECT MAX(TabRadkyDPH.Radek) FROM TabRadkyDPH
JOIN TabRadkyDPHDanKlice ON TabRadkyDPHDanKlice.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHDanKlice.IdDanovyKlic=#TabDenikDPH.IdDanovyKlic AND TabRadkyDPH.IdObdDPH=#TabDenikDPH.IdObdobiDPH)
FROM #TabDenikDPH
JOIN TabDanoveKlice ON TabDanoveKlice.Id=#TabDenikDPH.IdDanovyKlic
WHERE TabDanoveKlice.SmerPlneni=2 AND #TabDenikDPH.SmerPlneni=0
END
IF @VzorEU>399
BEGIN
IF @RezimDK=0
UPDATE #TabDenikDPH
SET VykazDPH11=
(SELECT MAX(TabRadkyDPH.Radek) FROM TabRadkyDPH
JOIN TabRadkyDPHCisUct ON TabRadkyDPHCisUct.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHCisUct.CisloUcet=#TabDenikDPH.DanovyUcet AND TabRadkyDPH.IdObdDPH=#TabDenikDPH.IdObdobiDPH AND
#TabDenikDPH.IdObdobi=CASE WHEN TabRadkyDPHCisUct.IdObdobi IS NULL THEN #TabDenikDPH.IdObdobi
ELSE TabRadkyDPHCisUct.IdObdobi
END)
FROM #TabDenikDPH
JOIN TabCisUctDef ON TabCisUctDef.IdObdobi=#TabDenikDPH.IdObdobi AND TabCisUctDef.CisloUcet=#TabDenikDPH.DanovyUcet
WHERE TabCisUctDef.MistoPlneni=4 AND #TabDenikDPH.SmerPlneni=0
ELSE
UPDATE #TabDenikDPH
SET VykazDPH11=
(SELECT MAX(TabRadkyDPH.Radek) FROM TabRadkyDPH
JOIN TabRadkyDPHDanKlice ON TabRadkyDPHDanKlice.IdRadekDPH=TabRadkyDPH.Id
WHERE TabRadkyDPHDanKlice.IdDanovyKlic=#TabDenikDPH.IdDanovyKlic AND TabRadkyDPH.IdObdDPH=#TabDenikDPH.IdObdobiDPH)
FROM #TabDenikDPH
JOIN TabDanoveKlice ON TabDanoveKlice.Id=#TabDenikDPH.IdDanovyKlic
WHERE TabDanoveKlice.SmerPlneni=2 AND #TabDenikDPH.SmerPlneni=0
END
IF (SELECT TOP 1 Legislativa FROM TabHGlob)=1 OR ((SELECT TOP 1 Legislativa FROM TabHGlob)=2 AND (SELECT DERezimPreuctovani FROM TabHGlob)=1)
BEGIN
UPDATE #tabDenikDPH
SET #TabDenikDPH.CeleCislo=ISNULL(CASE WHEN LEN(TabDenik.DPHPreuc) = 0 THEN NULL ELSE SUBSTRING(TabDenik.DPHPreuc,1,14) END,TabDenik.CeleCislo),
#TabDenikDPH.CeleCisloDlouhe=ISNULL(CASE WHEN LEN(TabDenik.DPHPreuc) = 0 THEN NULL ELSE SUBSTRING(TabDenik.DPHPreuc,1,11) END,TabDenik.CeleCisloDlouhe),
#TabDenikDPH.Sbornik=ISNULL(Left(TabDenik.DPHPreuc,3),TabDenik.Sbornik),
#TabDenikDPH.CisloDokladu=ISNULL(CASE WHEN LEN(TabDenik.DPHPreuc) = 0 
THEN NULL
ELSE SUBSTRING(TabDenik.DPHPreuc,CHARINDEX(N'/',TabDenik.DPHPreuc)+1,7 )
END,TabDenik.CisloDokladu)
FROM TabDenik
WHERE TabDenik.Sbornik=(SELECT TOP 1 DUDProPreuctovani FROM TabHGlob) AND TabDenik.Id=#TabDenikDPH.Id AND
NOT EXISTS(SELECT * FROM TabPreuctovaniDPH WHERE IdStorno=#TabDenikDPH.Id OR IdPreuc=#TabDenikDPH.Id)
END
IF (@VzorEU =-1) AND (SELECT ZvlastniUpravaSK FROM TabHGlob)=1
BEGIN
DECLARE @IdDenik INT, @IdFA INT, @IdFADPH INT, @DUDPreuc NVARCHAR(3), @SbornikFA NVARCHAR(3), @CisloDokladuFA INT, @CeleCisloFA NVARCHAR(14), @CeleCisloDlouheFA NVARCHAR(11)
DECLARE @DatumPoslUhr DATETIME, @NazevPoslPreuc NVARCHAR(20)
SELECT TOP 1 @DUDPreuc=DUDProPreuctovani FROM TabHGlob
DECLARE c CURSOR FAST_FORWARD LOCAL FOR
SELECT #TabDenikDPH.Id, TabPreuctovaniDPH.IdFA, TabPreuctovaniDPH.IdFADPH FROM #TabDenikDPH
JOIN TabPreuctovaniDPH ON TabPreuctovaniDPH.IdStorno=#TabDenikDPH.Id
WHERE #TabDenikDPH.Sbornik=@DUDPreuc
OPEN c
WHILE 1=1
BEGIN
FETCH NEXT FROM c INTO @IdDenik, @IdFA, @IdFADPH
IF @@fetch_status<>0 BREAK
SELECT @IdObdobi=TabDenik.IdObdobi, @NazevObdobi=TabObdobi.Nazev, @SbornikFA=TabDenik.Sbornik, @CisloDokladuFA=TabDenik.CisloDokladu,
@CeleCisloFA=TabDenik.CeleCislo, @CeleCisloDlouheFA=TabDenik.CeleCisloDlouhe
FROM TabDenik
JOIN TabObdobi ON TabObdobi.Id=TabDenik.IdObdobi WHERE TabDenik.Id=@IdFA
SET @DatumPoslUhr=NULL
SELECT @DatumPoslUhr=MAX(TabSaldo.DatumUhrazeno) FROM TabSaldo
JOIN TabVDenikSaldo ON TabVDenikSaldo.IdSaldo=TabSaldo.Id
JOIN TabSalSk ON TabSalSk.CisloSalSk=TabSaldo.CisloSalSk
WHERE TabVDenikSaldo.IdDenik=@IdFA AND TabSalSk.PreuctovaniSK=1
SET @NazevPoslPreuc=NULL
SELECT TOP 1 @NazevPoslPreuc=TabObdobiDPH.Nazev FROM TabObdobiDPH
JOIN TabPreuctovaniDPH ON TabPreuctovaniDPH.IdObdobiDPH=TabObdobiDPH.Id
WHERE TabPreuctovaniDPH.IdFA=@IdFA AND TabObdobiDPH.VzorEU>0
ORDER BY TabObdobiDPH.DatumDo DESC
UPDATE #TabDenikDPH SET IdObdobi=@IdObdobi,
NazevObdobi=@NazevObdobi,
Sbornik=@SbornikFA,
CisloDokladu=@CisloDokladuFA,
CeleCislo=@CeleCisloFA,
CeleCisloDlouhe=@CeleCisloDlouheFA,
PosledniUhrada=@DatumPoslUhr,
PosledniPreuc=@NazevPoslPreuc
WHERE Id=@IdDenik
UPDATE #TabDenikDPH SET PosledniUhrada=@DatumPoslUhr,
PosledniPreuc=@NazevPoslPreuc
WHERE Id=@IdFADPH
END
CLOSE c
DEALLOCATE c
END
DECLARE @Sbornik NVARCHAR(3), @CisloDokladu INT, @CisloOrg INT, @DICOrg NVARCHAR(15), @DanovyUcet NVARCHAR(30)
DECLARE c CURSOR FAST_FORWARD LOCAL FOR
SELECT IdObdobi,Sbornik,CisloDokladu,DanovyUcet FROM #TabDenikDPH
WHERE DICOrg IS NULL OR DICOrg=''
GROUP BY IdObdobi,Sbornik,CisloDokladu,DanovyUcet
OPEN c
WHILE 1=1
BEGIN
FETCH NEXT FROM c INTO @IdObdobi,@Sbornik,@CisloDokladu,@DanovyUcet
IF @@fetch_status<>0 BREAK
SET @DICOrg=NULL
SELECT TOP 2 @DICOrg=DICOrg FROM TabDenik
WHERE IdObdobi=@IdObdobi AND Sbornik=@Sbornik AND CisloDokladu=@CisloDokladu AND DICOrg IS NOT NULL AND DICOrg<>''
GROUP BY DICOrg
IF @@ROWCOUNT = 1
BEGIN
IF @DICOrg IS NOT NULL
UPDATE #TabDenikDPH SET DICOrg=@DICOrg
WHERE IdObdobi=@IdObdobi AND Sbornik=@Sbornik AND CisloDokladu=@CisloDokladu  AND DanovyUcet=@DanovyUcet AND (DICOrg IS NULL OR DICOrg='')
END
END
CLOSE c
DEALLOCATE c
DECLARE @CeleCislo NVARCHAR(14),@CelyNazevUcet NVARCHAR(251),@Count INT,@ParovaciZnak NVARCHAR(20),@tz INT
SET @UpravaPZ=0
IF EXISTS(SELECT * FROM TabHGlob WHERE KontrVykDPH=1) OR EXISTS(SELECT * FROM TabHGlob WHERE KontrHlaDPH=1)
SET @UpravaPZ=1
IF @UpravaPZ=1
BEGIN
DECLARE c CURSOR FAST_FORWARD LOCAL FOR
SELECT Id,IdObdobi,CeleCislo,CelyNazevUcet,Sbornik,CisloDokladu,ParovaciZnak FROM #TabDenikDPH
OPEN c
WHILE 1=1
BEGIN
FETCH NEXT FROM c INTO @IdDenik,@IdObdobi,@CeleCislo,@CelyNazevUcet,@Sbornik,@CisloDokladu,@ParovaciZnak
IF @@fetch_status<>0 BREAK
SELECT @PorCisKV=PorCisKV FROM TabDenik WHERE Id=@IdDenik
IF @PorCisKV<>''
BEGIN
UPDATE #TabDenikDPH SET ParovaciZnak=@PorCisKV WHERE Id=@IdDenik
SET @ParovaciZnak=@PorCisKV
END
IF @ParovaciZnak=''
BEGIN
IF EXISTS(SELECT * FROM TabHGlob WHERE KontrHlaDPH=1) AND @VzorEU>-1 AND @VzorEU<400
BEGIN
SET @IdKontrDPH=NULL
SELECT TOP 1 @IdKontrDPH=TabKontrHlaDPH.Id FROM TabKontrHlaDPH
JOIN TabVDenikKH ON TabVDenikKH.IdKH=TabKontrHlaDPH.Id
WHERE TabVDenikKH.IdDenik=@IdDenik AND
TabKontrHlaDPH.DatumOd_Sys>=@DatumOd AND TabKontrHlaDPH.DatumDo_Sys<=@DatumDo
ORDER BY TabKontrHlaDPH.Id DESC
IF @IdKontrDPH IS NOT NULL
EXEC dbo.hp_VratPorCisKHDoklad @IdKontrDPH, @IdDenik, @IdObdDPH, @PorCisKV OUT, @ChybaKV OUT, @RezimDK
ELSE
EXEC dbo.hp_VratPorCisKHDoklad_BezKH @IdDenik,@IdObdDPH, @PorCisKV OUT, @ChybaKV OUT, @RezimDK
END
IF EXISTS(SELECT * FROM TabHGlob WHERE KontrVykDPH=1) AND @VzorEU>399 AND @VzorEU<500
BEGIN
SET @IdKontrDPH=NULL
SELECT TOP 1 @IdKontrDPH=TabKontrVykDPH.Id FROM TabKontrVykDPH
JOIN TabDenik ON TabDenik.IdKVDPH=TabKontrVykDPH.Id
JOIN TabObdobiDPH ON TabObdobiDPH.Id=@IdObdDPH
WHERE TabDenik.Id=@IdDenik AND
(TabObdobiDPH.Rok=CASE WHEN TabDenik.DatumKV IS NULL THEN TabKontrVykDPH.Rok ELSE TabObdobiDPH.Rok END AND
ISNULL(TabObdobiDPH.Ctvrtleti,'')=CASE WHEN TabDenik.DatumKV IS NULL THEN ISNULL(TabKontrVykDPH.Ctvrtleti,'') ELSE ISNULL(TabObdobiDPH.Ctvrtleti,'') END AND
ISNULL(TabObdobiDPH.Mesic_Sys,'')=CASE WHEN TabDenik.DatumKV IS NULL THEN ISNULL(TabKontrVykDPH.Mesic,'') ELSE ISNULL(TabObdobiDPH.Mesic_Sys,'') END) AND
(TabKontrVykDPH.Rok=CASE WHEN TabDenik.DatumKV IS NULL THEN TabKontrVykDPH.Rok ELSE CAST(DATEPART(YEAR,TabDenik.DatumKV) AS NVARCHAR) END AND
ISNULL(TabKontrVykDPH.Ctvrtleti,'')=CASE WHEN TabDenik.DatumKV IS NULL THEN ISNULL(TabKontrVykDPH.Ctvrtleti,'') ELSE
CASE WHEN TabKontrVykDPH.Ctvrtleti IS NULL THEN ISNULL(TabKontrVykDPH.Ctvrtleti,'') ELSE CAST(DATEPART(QUARTER,TabDenik.DatumKV) AS NVARCHAR) END END AND
ISNULL(TabKontrVykDPH.Mesic,'')=CASE WHEN TabDenik.DatumKV IS NULL THEN ISNULL(TabKontrVykDPH.Mesic,'') ELSE
CASE WHEN TabKontrVykDPH.Mesic IS NULL THEN ISNULL(TabKontrVykDPH.Mesic,'') ELSE CAST(DATEPART(MONTH,TabDenik.DatumKV) AS NVARCHAR) END END) AND
TabObdobiDPH.ISOKodZeme=N'SK'
ORDER BY TabKontrVykDPH.Id DESC
IF @IdKontrDPH IS NOT NULL
EXEC dbo.hp_VratPorCisKVDoklad @IdKontrDPH, @IdDenik, @PorCisKV OUT, @ChybaKV OUT, @RezimDK
ELSE
EXEC dbo.hp_VratPorCisKVDoklad_BezKV @IdDenik, @PorCisKV OUT, @ChybaKV OUT, @RezimDK
END
IF @ChybaKV<>''
SET @PorCisKV=N''
UPDATE #TabDenikDPH SET ParovaciZnak=@PorCisKV WHERE Id=@IdDenik
END
END
CLOSE c
DEALLOCATE c
END
DECLARE c CURSOR FAST_FORWARD LOCAL FOR
SELECT IdObdobi,CeleCislo,CelyNazevUcet,COUNT(*),Sbornik,CisloDokladu FROM #TabDenikDPH
GROUP BY IdObdobi,CeleCislo,CelyNazevUcet,Sbornik,CisloDokladu
OPEN c
WHILE 1=1
BEGIN
FETCH NEXT FROM c INTO @IdObdobi,@CeleCislo,@CelyNazevUcet,@Count,@Sbornik,@CisloDokladu
IF @@fetch_status<>0 BREAK
SELECT @ParovaniPopis=ParovaniDPH, @ParovaniPZ=ParovaniDPH_PZ FROM TabSbornik WHERE Cislo=@Sbornik
IF @ParovaniPZ=0
BEGIN
UPDATE #TabDenikDPH SET ParovaciZnak=''
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND Sbornik=@Sbornik
END
ELSE
BEGIN
IF @UpravaPZ=0
BEGIN
IF NOT EXISTS(SELECT*FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND
ParovaciZnak<>'')
BEGIN
SET @ParovaciZnak=''
SELECT @ParovaciZnak=ParovaciZnak FROM TabDenik
JOIN TabCisUctDef ON TabCisUctDef.CisloUcet=TabDenik.CisloUcet AND TabCisUctDef.IdObdobi=TabDenik.IdObdobi AND
EXISTS(SELECT*FROM TabCisUcSalSk WHERE TabCisUcSalSk.CisloUcet=TabCisUctDef.CisloUcet)
WHERE TabDenik.IdObdobi=@IdObdobi AND TabDenik.Sbornik=@Sbornik AND TabDenik.CisloDokladu=@CisloDokladu AND
TabDenik.ParovaciZnak<>''
IF @@ROWCOUNT=1
BEGIN
UPDATE #TabDenikDPH SET ParovaciZnak=@ParovaciZnak
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
END
END
ELSE
IF @Count<>(SELECT COUNT(*)FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND
ParovaciZnak<>'')
BEGIN
SELECT @ParovaciZnak=ParovaciZnak FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND ParovaciZnak<>''
GROUP BY ParovaciZnak
IF @@ROWCOUNT=1
BEGIN
UPDATE #TabDenikDPH SET ParovaciZnak=@ParovaciZnak
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND ParovaciZnak=''
END
END
END
END
IF NOT EXISTS(SELECT*FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloOrg IS NOT NULL)
BEGIN
SET @CisloOrg=NULL
SELECT @CisloOrg=TabDenik.CisloOrg FROM TabDenik
JOIN TabCisUctDef ON TabCisUctDef.CisloUcet=TabDenik.CisloUcet AND TabCisUctDef.IdObdobi=TabDenik.IdObdobi AND
EXISTS(SELECT*FROM TabCisUcSalSk where TabCisUcSalSk.CisloUcet=TabCisUctDef.CisloUcet)
WHERE TabDenik.IdObdobi=@IdObdobi AND TabDenik.Sbornik=@Sbornik AND TabDenik.CisloDokladu=@CisloDokladu AND
TabDenik.CisloOrg IS NOT NULL
IF @@ROWCOUNT=1
BEGIN
UPDATE #TabDenikDPH SET CisloOrg=@CisloOrg
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
END
END
ELSE
IF @Count<>(SELECT COUNT (*) FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND
CisloOrg IS NOT NULL)
BEGIN
SELECT @CisloOrg=CisloOrg FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloOrg IS NOT NULL
GROUP BY CisloOrg
IF @@ROWCOUNT=1
BEGIN
UPDATE #TabDenikDPH SET CisloOrg=@CisloOrg
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloOrg IS NULL
END
END
SELECT TOP 2 @Utvar=Utvar FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY Utvar
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET Utvar=NULL
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND Utvar IS NOT NULL
END
SELECT TOP 2 @CisloZakazky=CisloZakazky FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY CisloZakazky
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET CisloZakazky=NULL
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloZakazky IS NOT NULL
END
SELECT TOP 2 @NO=CisloNakladovyOkruh FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY CisloNakladovyOkruh
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET CisloNakladovyOkruh=NULL
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloNakladovyOkruh IS NOT NULL
END
SELECT TOP 2 @IdVozidlo=IdVozidlo FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY IdVozidlo
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET IdVozidlo=NULL
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND IdVozidlo IS NOT NULL
END
SELECT TOP 2 @CisloZam=CisloZam FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY CisloZam
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET CisloZam=NULL
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND CisloZam IS NOT NULL
END
IF @ParovaniPopis=0
BEGIN
SELECT TOP 2 @Popis=Popis FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
GROUP BY Popis
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET Popis=(SELECT TOP 1 Popis FROM #TabDenikDPH WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet AND Popis<>'' ORDER BY CisloRadku ASC)
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo AND CelyNazevUcet=@CelyNazevUcet
END
END
IF (SELECT TOP 1 Legislativa FROM TabHGlob)=1 OR ((SELECT TOP 1 Legislativa FROM TabHGlob)=2 AND (SELECT DERezimPreuctovani FROM TabHGlob)=1)
BEGIN
SELECT TOP 2 @IDDokladyZbozi=IDDokladyZbozi FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo
GROUP BY IDDokladyZbozi
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET IdDokladyZbozi=(SELECT TOP 1 IdDokladyZbozi FROM #TabDenikDPH WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo /*AND CelyNazevUcet=@CelyNazevUcet */AND IDDokladyZbozi is not NULL ORDER BY CisloRadku ASC)
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo
END
SELECT TOP 2 @IDPoklDoklad=IDPoklDoklad FROM #TabDenikDPH
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo /*AND CelyNazevUcet=@CelyNazevUcet*/
GROUP BY IDPoklDoklad
IF @@ROWCOUNT > 1
BEGIN
UPDATE #TabDenikDPH SET IdPoklDoklad=(SELECT TOP 1 IdPoklDoklad FROM #TabDenikDPH WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo /*AND CelyNazevUcet=@CelyNazevUcet*/ AND IDPoklDoklad is NOT NULL ORDER BY CisloRadku ASC)
WHERE IdObdobi=@IdObdobi AND CeleCislo=@CeleCislo /*AND CelyNazevUcet=@CelyNazevUcet*/
END
END
END
CLOSE c
DEALLOCATE c
UPDATE #TabDenikDPH SET KodZeme=SUBSTRING(DICOrg,1,2)
FROM #TabDenikDPH
JOIN TabCisUctDef ON TabCisUctDef.CisloUcet=#TabDenikDPH.DanovyUcet AND TabCisUctDef.IdObdobi=#TabDenikDPH.IdObdobi
WHERE TabCisUctDef.ClenitPodleZeme=1
UPDATE #TabDenikDPH SET KodZeme=N'GR' WHERE KodZeme=N'EL'
UPDATE #TabDenikDPH SET KodZeme=TabCisOrg.IdZeme
FROM #TabDenikDPH
JOIN TabCisUctDef ON TabCisUctDef.CisloUcet=#TabDenikDPH.DanovyUcet AND TabCisUctDef.IdObdobi=#TabDenikDPH.IdObdobi
JOIN TabCisOrg ON TabCisOrg.CisloOrg=#TabDenikDPH.CisloOrg
WHERE TabCisUctDef.ClenitPodleZeme=1 AND #TabDenikDPH.KodZeme IS NULL OR #TabDenikDPH.KodZeme=''
UPDATE #TabDenikDPH SET DanovyUcet=NULL
IF @RezimDK=0
UPDATE #TabDenikDPH SET ISOKodZeme=NULL
ELSE
UPDATE #TabDenikDPH SET ISOKodZeme=@ISOKodZeme WHERE ISOKodZeme IS NULL
INSERT #TabDenikDPH
(Id,IdObdobi,NazevObdobi,CeleCislo,CeleCisloDlouhe,IdDokladyZbozi,IdPoklDoklad,ParovaciZnak,CelyNazevUcet,DatumDUZP,DatumDoruceni,
Utvar,CisloZakazky,CisloNakladovyOkruh,IdVozidlo,CisloOrg,CisloZam,VykazDPH11,
SazbaDane,ZakladDane,CastkaDane,OdchylkaDane,Seskupeno,Sbornik,CisloDokladu,IdObdobiDPH,Popis,DICOrg,
KodZeme,IdDanovyKlic,ISOKodZeme,CastkaDaneKracena,SmerPlneni,PosledniUhrada,PosledniPreuc,DelkaPorCis)
SELECT
MAX(Id),IdObdobi,NazevObdobi,CeleCislo,CeleCisloDlouhe,IdDokladyZbozi,IdPoklDoklad,ParovaciZnak,CelyNazevUcet,DatumDUZP,DatumDoruceni,
Utvar,CisloZakazky,CisloNakladovyOkruh,IdVozidlo,CisloOrg,CisloZam,VykazDPH11,
SazbaDane,SUM(ISNULL(ZakladDane,0)),SUM(ISNULL(CastkaDane,0)),SUM(ISNULL(OdchylkaDane,0)),1,Sbornik,CisloDokladu,IdObdobiDPH,
Popis,DICOrg,KodZeme,IdDanovyKlic,ISOKodZeme,SUM(ISNULL(CastkaDaneKracena,0)),SmerPlneni,PosledniUhrada,PosledniPreuc,DelkaPorCis
FROM #TabDenikDPH
GROUP BY
IdObdobi,NazevObdobi,CeleCislo,CeleCisloDlouhe,IdDokladyZbozi,IdPoklDoklad,ParovaciZnak,CelyNazevUcet,DatumDUZP,DatumDoruceni,
Utvar,CisloZakazky,CisloNakladovyOkruh,IdVozidlo,CisloOrg,CisloZam,VykazDPH11,SazbaDane,Sbornik,CisloDokladu,IdObdobiDPH,
Popis,DICOrg,KodZeme,IdDanovyKlic,ISOKodZeme,SmerPlneni,PosledniUhrada,PosledniPreuc,DelkaPorCis
DELETE #TabDenikDPH WHERE Seskupeno=0

