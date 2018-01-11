-- Create the data set table of points that are to be used to create the clusters
CREATE TABLE Points (PId INTEGER, X FLOAT, Y FLOAT);
-- Create the table that will hold the centroids
CREATE TABLE Centroids (cid INTEGER, X FLOAT, Y FLOAT);
-- This tracks the centroid that each data point is assigned to
CREATE TABLE Cluster_Assignments (CId INTEGER, PId INTEGER, X FLOAT, Y FLOAT);
-- This tracks the previous cluster assignment of each data points
CREATE TABLE Prev_Cluster_Assignments (CId INTEGER, PId INTEGER, X FLOAT, Y FLOAT);

-- Insert random data points into Points where the X and Y values range between
-- 1.0 and 10.0.
INSERT INTO Points VALUES
  (1, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (2, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (3, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (4, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (5, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (6, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (7, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (8, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (9, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1),
  (10, floor(random()*(10-1+1))+1, floor(random()*(10-1+1))+1);

-- This view tracks the number of data points in the data set
CREATE VIEW N AS (SELECT COUNT(1) FROM Points);

-- This function returns the number of data points that switched clusters
-- between iterations of the KMeans algorithm.
-- It takes nothing as input.
CREATE FUNCTION Switched () RETURNS BIGINT AS
$$
  SELECT COUNT(1)
  FROM Cluster_Assignments ca, Prev_Cluster_Assignments pca
  WHERE ca.PId = pca.PId AND ca.CId <> pca.CId;
$$ LANGUAGE SQL;

-- This function takes a X FLOAT and Y FLOAT value as input and returns an
-- INTEGER representing the cluster the given point should be assigned to
CREATE FUNCTION Assign_Cluster(xval FLOAT, yval FLOAT) RETURNS INTEGER AS
$$
  SELECT c_one.CId
  FROM Centroids c_one
  WHERE NOT EXISTS (SELECT c_two.CId
                   FROM Centroids c_two
                   WHERE |/((c_one.X - xval)^2.0 + (c_one.Y - yval)^2.0) > |/((c_two.X - xval)^2.0 + (c_two.Y - yval)^2.0));
$$ LANGUAGE SQL;

-- This is the kmeans function that learns that finds k centroids that define
-- the center of mass for the possible clusters in the data
-- It takes an INTEGER value k representing the number of centroids to learn
-- as input
CREATE FUNCTION KMeans(k INTEGER) RETURNS TABLE (cid INTEGER, X FLOAT, Y FLOAT) AS
$$
  BEGIN
  -- Populate the centroids table with k random points from the Points table
  INSERT INTO Centroids (SELECT p.PId as CId, p.X, p.Y
                         FROM Points p ORDER BY random() limit k);
  WHILE (NOT EXISTS(SELECT * FROM Prev_Cluster_Assignments) OR
         CAST(Switched() AS FLOAT) / CAST((SELECT * FROM N) AS FLOAT) > .1) LOOP
         -- Clear the table tracking the previous cluster each data point was
         -- assigned to.
         DELETE FROM Prev_Cluster_Assignments;
         -- Move data from the current to the previous cluster assignments table
         INSERT INTO Prev_Cluster_Assignments (SELECT * FROM Cluster_Assignments);
         -- Re-assign the clusters
         INSERT INTO Cluster_Assignments (SELECT Assign_Cluster(CAST(p.x AS FLOAT), CAST(p.y AS FLOAT)), p.Pid, p.X, p.Y
                                          FROM Points p);
        -- Update the centroids
        DELETE FROM Centroids;
        -- Update the centroids
        INSERT INTO Centroids (SELECT ca.CId,
                                      CAST(SUM(ca.X) AS FLOAT)/CAST(COUNT(1) AS FLOAT) AS X,
                                      CAST(SUM(ca.Y) AS FLOAT)/CAST(COUNT(1) AS FLOAT) AS Y
                               FROM Cluster_Assignments ca
                               GROUP BY(ca.CId));

  END LOOP;
  RETURN QUERY (SELECT * FROM Centroids);
  END;
$$ LANGUAGE PLPGSQL;
