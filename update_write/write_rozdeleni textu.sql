USE AdventureWorks2017;  
GO  
DECLARE @MyTableVar TABLE (  
    SummaryBefore NVARCHAR(max),  
    SummaryAfter NVARCHAR(max)); 
	
UPDATE Production.Document  
SET DocumentSummary .WRITE (CHAR(13)+CHAR(10),28,10)  
OUTPUT deleted.DocumentSummary,   
       inserted.DocumentSummary   
    INTO @MyTableVar
WHERE Title = N'Front Reflector Bracket Installation';  


SELECT SummaryBefore, SummaryAfter   
FROM @MyTableVar;  

