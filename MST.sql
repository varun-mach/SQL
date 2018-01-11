create table if not exists SpanningTree (
   Source integer,
   Target integer);

delete from SpanningTree;

create table if not exists RemainingEdges (
   Source integer,
   Target integer,
   Cost   integer);

delete from RemainingEdges;

create or replace function SP() returns void as
$$
declare v    integer;
        w    integer;
        n    integer;   --number of nodes in weightedgraph
        m    integer;   --number of edges in spanning tree
begin 
  m := 0;

  insert into RemainingEdges (select * from WeightedGraph);

  select count(distinct e.source) into n
  from   WeightedGraph e;

  select e.source, e.target into v, w
  from   WeightedGraph e
  where  e.cost <= ALL (select e1.cost
                        from   WeightedGraph e1)
  order by random() limit 1;

  insert into SpanningTree values (v,w), (w,v);


  while (m < n-1) 
  loop
     m := m+1;
   
     delete from RemainingEdges 
            where source in (select e.source
                             from   SpanningTree e) and
                  target in (select e.source
                             from   SpanningTree e);

     select e.source, e.target into v, w
     from   RemainingEdges e
     where  e.cost <= ALL (select e1.cost
                           from   RemainingEdges e1)
     order by random() limit 1;     

     insert into SpanningTree values (v,w), (w,v);
  end loop;
end;
$$ language plpgsql;

