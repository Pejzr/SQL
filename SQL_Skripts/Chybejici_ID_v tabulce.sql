-------------------------------------------------------------------------------------------------------------------------------------
--									SKRIPT NA VYPOÈÍTÁNÍ ROZSAHU CHYBÌJÍCÍCH IDÈEK V TABULCE
-------------------------------------------------------------------------------------------------------------------------------------


create table #SortRange (
	id int identity(1,1),
	SortedNumber int
)

create table #RangeWithDiff (
	id1 int,
	id2 int,
	value1 int,
	value2 int,
	diff_value1_value2 int
)


-------------------------------------------------------------------------------------------------------------------------------------
--											ZDE VYBRAT TABULKU ZE KTERÉ BUDEME BRÁT 
--											JE TØEBA DOPLNIT IDÈKO A TABULKU !!!
-------------------------------------------------------------------------------------------------------------------------------------

insert into #SortRange
select ID from TABULKA order by ID asc


declare @maxNumber int = (select max(id) from #SortRange);
declare @counter int = (select min(id) from #SortRange);
declare @LSid int, @GTid int, @id1 int, @id2 int;

while @counter < @maxNumber
begin
	set @LSid = (select SortedNumber from #SortRange where id = @counter);
	set @GTid = (select SortedNumber from #SortRange where id = (@counter +1));
	set @id1 = (select id from #SortRange where id = @counter);
	set @id2 = (select id from #SortRange where id = (@counter + 1));
	if (@GTid - @LSid > 1)
		begin
			insert into #RangeWithDiff(id1, id2, value1, value2, diff_value1_value2) values(@id1, @id2, @LSid, @GTid, @GTid - @LSid);
		end
	else
		begin
			insert into #RangeWithDiff(id1, id2, value1, value2, diff_value1_value2) values(@id1, @id2, @LSid, @GTid, null);
		end
	set @counter = @counter +1;
end

select * from #RangeWithDiff