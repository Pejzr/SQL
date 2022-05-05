--drop table #VyuzitiPameti
create table #VyuzitiPameti (
	id int identity(1,1),
	cas time(3),
	memory_in_use int
)


while 1 = 1
begin



insert into #VyuzitiPameti values((SELECT convert(time(0),getDate())), (select physical_memory_in_use_kb from sys.dm_os_process_memory))
WAITFOR DELAY '00:00:01'; 
end

--select * from #VyuzitiPameti