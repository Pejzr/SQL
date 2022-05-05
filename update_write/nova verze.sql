-- Pochopil jsem, že cílem je na konci sloupce Poznamka pøidat konec øádku

/*
	ntext je deprecated, je tedy potøeba i tento typ nahradit.
*/
declare @text nvarchar(max), @Poznamka nvarchar(max), @Id int

set @text =  CHAR(13)+CHAR(10)

/*
	Na ntext nelze aplikovat .WRITE metodu, která je náhradou za UPDATETEXT
*/
update TabDosleObjH20
set Poznamka .WRITE (@text,NULL,0)  
where Id = 26