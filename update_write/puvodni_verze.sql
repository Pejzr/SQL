SELECT @ptrval = TEXTPTR(Poznamka) FROM TabDosleObjH20 WHERE ID = @Id
set @text =  CHAR(13)+CHAR(10)
UPDATETEXT TabDosleObjH20.Poznamka @ptrval NULL 0 @text
UPDATETEXT TabDosleObjH20.Poznamka @ptrval NULL 0 @Poznamka
