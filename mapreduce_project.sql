
CREATE OR REPLACE FUNCTION mapper_project(a integer, b integer) 
       RETURNS TABLE (a integer, b integer) AS
$$
SELECT mapper_project.a, mapper_project.b;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION reducer_project(a integer, bs INTEGER[]) 
RETURNS TABLE(a integer, a1 integer) AS 
$$
SELECT reducer_project.a, reducer_project.a; 
$$ LANGUAGE SQL;


WITH 
    -- mapper phase
    map_output AS    
   (SELECT q.a, q.b
    FROM   R r, 
                 LATERAL(SELECT p.a as a, p.b as b
                         FROM   mapper_project(r.a,r.b) p) q),
    -- group phase
    group_output AS
    (SELECT DISTINCT q.a, (SELECT ARRAY(SELECT q1.b
                                           FROM   map_output  q1
                                           WHERE  q1.a = q.a)) as bs
     FROM map_output q),
     -- reducer phase
     reduce_output AS
     (SELECT t.a, t.a1
      FROM   group_output r, LATERAL(SELECT s.a as a, s.a as a1 
                                     FROM   reducer_project(r.a, r.bs) s) t)
                               
   
-- output    
SELECT *
FROM   reduce_output;