drop table if exists A;
create table A(x integer);
insert into A values(1);
insert into A values(2);
insert into A values(3);
insert into A values(4);
insert into A values(5);
create table powersetA(a integer[]);

create or replace function findpowerset(a integer[])

returns void as 
$$
declare b integer;
arr integer[];

begin
drop table if exists powersetA;
create table powersetA(a integer[]);

foreach b in array $1
loop
	for arr in select * from powersetA
	loop
		arr := array_append(arr,b);
		insert into powersetA values (arr);	
	end loop;
	insert into powersetA select array[b];
end loop;
insert into powersetA values(array[]::integer[]);
end;
$$language plpgsql;


select findpowerset(q.x) from (select array(select x from a ) as x) q;
select a as powersets from powersetA a order by cardinality(a),a ;
