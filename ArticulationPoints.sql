drop table if exists TC;
drop table if exists graph;
create table graph(source integer, target integer);
create table tc(source integer, target integer);
insert into graph values (1,2);
insert into graph values (2,1);
insert into graph values (1,3);
insert into graph values (3,1);
insert into graph values (2,3);
insert into graph values (3,2);
insert into graph values (2,4);
insert into graph values (4,2);
insert into graph values (2,5);
insert into graph values (5,2);
insert into graph values (4,5);
insert into graph values (5,4);
 
create or replace function new_TC_pairs()
returns table (source integer, target integer) AS
$$
(select TC.source, graph.target
from TC, graph
where TC.target = graph.source and TC.source<>graph.target)
except
(select source, target
from TC);
$$ LANGUAGE SQL;


create or replace function Transitive_Closure()
returns void as $$
begin
drop table if exists TC;
create table TC(source integer, target integer);
insert into TC select * from graph;
while exists(select * from new_TC_pairs())
loop
insert into TC select * from new_TC_pairs();
end loop;
end;
$$ language plpgsql;


create or replace function new_TC1_pairs()
returns table (source integer, target integer) AS
$$
(select TC1.source, new_graph.target
from TC1, new_graph
where TC1.target = new_graph.source)
except
(select source, target
from TC1);
$$ LANGUAGE SQL;


create or replace function ap(p integer)
returns boolean as 
$$
declare 
totalnodes integer:= 0;
apnodes integer := 0;
a RECORD;
b RECORD;

begin
	drop table if exists new_graph;
	create table new_graph(source integer, target integer);
	insert into new_graph select * from graph g where g.source <> p and g.target <> p ;

	drop table if exists TC1;
	create table TC1(source integer, target integer);
	insert into TC1 select * from new_graph;
	while exists(select * from new_TC1_pairs())
	loop
	insert into TC1 select * from new_TC1_pairs();
	end loop;	

	drop table if exists new_nodes;
	create table new_nodes(nodes integer);
	insert into new_nodes ((select graph.source from graph where graph.source <> p) 
	union
	select graph.target from graph where graph.target <> p );	

	for a in select * from new_nodes
	loop
		for b in select * from new_nodes where new_nodes.nodes <> a.nodes
		loop	
			if not exists(select 1 from tc1 where tc1.source = a.nodes and tc1.target = b.nodes) then
				return true;	
			end if;
		end loop;	
	end loop;

	return false;

end;

$$ language plpgsql;

 
select distinct graph.source as articulation_point from graph where  (ap(graph.source)); 
