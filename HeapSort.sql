

drop table if exists data;
create table data(index integer, value integer);
insert into data values(1,3);
insert into data values(2,1);
insert into data values(3,2);
insert into data values(4,0);
insert into data values(5,7);	
insert into data values(6,4);	

drop table if exists buildheap;
create table buildheap(index integer, value integer);
insert into buildheap select * from data;	

create or replace function binaryheap()
returns void AS
$$
declare
i integer;
k integer;
begin
select into i (count(*)/2) from data;

while i >0
loop
	perform maxheapify(i);
	i = i-1;
end loop; 

end;

$$language plpgsql;

create or replace function maxheapify(i integer)
returns void AS
$$

declare
a RECORD;
parent integer;
heapsize integer := 0;
leftnode integer;
rightnode integer;
curr integer;
temp integer;
largest integer;
ln integer;
rn integer;

begin

select into heapsize count(*) from buildheap;

while(i<=heapsize)
loop

leftnode = 2*i;
rightnode = (2*i)+1;

select into ln buildheap.value from buildheap where buildheap.index = leftnode;
select into rn buildheap.value from buildheap where buildheap.index = rightnode;
select into curr buildheap.value from buildheap where buildheap.index = i;
temp = curr;

if leftnode<=heapsize AND ln > curr then
	largest =  leftnode;
else
	largest = i;	
end if;	

select into curr buildheap.value from buildheap where buildheap.index = largest;

if rightnode<=heapsize and rn >curr then
	largest = rightnode;
end if;

select into curr buildheap.value from buildheap where buildheap.index = largest;

if largest <> i then
	update buildheap set value = curr where index = i;
	update buildheap set value = temp where index = largest;
	i = largest;
else
	exit;		 	
end if;	

end loop;

end;
$$language plpgsql;


create or replace function insert(key integer)
returns void AS
$$
declare
heapsize integer;
newindex integer;
i integer;
curr integer;
parent integer;

begin

select into heapsize count(*) from buildheap;
select into curr buildheap.value from buildheap where buildheap.index = heapsize;

newindex = heapsize + 1;
insert into buildheap values (newindex,key);   

if key < curr then
	return;
end if;

parent = newindex/2;


while newindex > 1 and exists(select * from buildheap where buildheap.index = parent and buildheap.value < (select buildheap.value from buildheap where buildheap.index = newindex))
loop
	select into curr buildheap.value from buildheap where buildheap.index = newindex;
	update buildheap set value = (select buildheap.value from buildheap where buildheap.index = parent) where index = newindex;
	update buildheap set value = curr where index = parent;		
	newindex = parent;	
	parent = parent/2;
end loop; 	

end;

$$language plpgsql;


create or replace function maxextract()
returns void AS
$$

declare
heapsize integer;
i integer :=1;
curr integer;
begin	

select into heapsize count(*) from buildheap;
select into curr buildheap.value from buildheap where buildheap.index = heapsize;	
update buildheap set value = curr where index = 1;
delete from buildheap where index = heapsize;	
perform maxheapify(1);
end;

$$language plpgsql;



create or replace function heapsort()
returns void AS
$$

declare
heapsize integer;
i integer :=1;
curr integer;
begin

drop table if exists sort_data;
create table sort_data(index integer, value integer);

select into heapsize count(*) from buildheap;

while heapsize >= 1
loop
	select into curr buildheap.value from buildheap where buildheap.index = 1;
	insert into sort_data values (heapsize,curr);
	select into curr buildheap.value from buildheap where buildheap.index = heapsize;	
	update buildheap set value = curr where index = 1;
	delete from buildheap where index = heapsize;	
	heapsize = heapsize - 1;
	perform maxheapify(1);
	i = i+1;	
end loop;


end;

$$language plpgsql;
