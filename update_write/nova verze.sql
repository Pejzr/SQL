-- Pochopil jsem, �e c�lem je na konci sloupce Poznamka p�idat konec ��dku

/*
	ntext je deprecated, je tedy pot�eba i tento typ nahradit.
*/
declare @text nvarchar(max), @Poznamka nvarchar(max), @Id int

set @text =  CHAR(13)+CHAR(10)

/*
	Na ntext nelze aplikovat .WRITE metodu, kter� je n�hradou za UPDATETEXT
*/
update TabDosleObjH20
set Poznamka .WRITE (@text,NULL,0)  
where Id = 26