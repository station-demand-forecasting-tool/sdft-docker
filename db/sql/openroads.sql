-- rename gid columns
ALTER TABLE openroads.roadnodes RENAME gid TO id
;

ALTER TABLE openroads.roadlinks RENAME gid TO id
;

CREATE INDEX roadnodes_id_idx
ON
    openroads.roadnodes
USING btree
    (
        ID
    )
;

CREATE INDEX roadnodes_identifier_idx
ON
    openroads.roadnodes
USING btree
    (
        identifier
    )
;

CREATE INDEX roadlinks_id_idx
ON
    openroads.roadlinks
USING btree
    (
        ID
    )
;

CREATE INDEX roadlinks_identifier_idx
ON
    openroads.roadlinks
USING btree
    (
        identifier
    )
;

-- Open Roads is provided with separate shapefiles, each covering 100 x 100 km, and
-- these are all appended to the same table in PostgreSQL.
-- There is overlap between these shapefiles so we now need to find and remove duplicate nodes and links.
-- This can be done using the 'identifier' field.
-- delete duplicates from the roadnodes table
DELETE
FROM
    openroads.roadnodes
WHERE
    ID IN
    (
        SELECT
            ID
        FROM
            (
                SELECT
                    ID,
                    ROW_NUMBER ( ) OVER ( PARTITION BY identifier ORDER BY
                                         ID ) AS rnum
                FROM
                    openroads.roadnodes
            )
            T
        WHERE
            T.rnum > 1
    )
;

-- delete duplicates from the roadlinks table
DELETE
FROM
    openroads.roadlinks
WHERE
    ID IN
    (
        SELECT
            ID
        FROM
            (
                SELECT
                    ID,
                    ROW_NUMBER ( ) OVER ( PARTITION BY identifier ORDER BY
                                         ID ) AS rnum
                FROM
                    openroads.roadlinks
            )
            T
        WHERE
            T.rnum > 1
    )
;

-- pgRouting requires the source and target nodes to be integer ids.
-- In the current Open Roads shapefile dataset the start and end nodes are provided in 38 character alphanumeric format.
-- We can create new start and end node ids by looking up the identifier of each node in the roadnodes table
-- and retrieving the unique id of that record.
-- drop roadlinks indexes before updating table for performance reasons - have to specify schema
DROP INDEX openroads.roadlinks_id_idx;
DROP INDEX openroads.roadlinks_identifier_idx;
-- add souce and target columns
ALTER TABLE openroads.roadlinks ADD COLUMN SOURCE INTEGER,
    ADD COLUMN target                             INTEGER
;

-- populate source and target fields using unique id from roadnodes table
UPDATE
    openroads.roadlinks l
SET SOURCE = n.ID
FROM
    openroads.roadnodes n
WHERE
    l.startnode = n.identifier
;

UPDATE
    openroads.roadlinks l
SET target = n.ID
FROM
    openroads.roadnodes n
WHERE
    l.endnode = n.identifier
;

-- Add and rename columns
ALTER TABLE openroads.roadlinks ADD COLUMN speed_mph INTEGER,
    ADD COLUMN cost_time DOUBLE PRECISION                   ,
    ADD COLUMN rcost_len DOUBLE PRECISION
;

-- rename length column
ALTER TABLE openroads.roadlinks RENAME COLUMN LENGTH TO cost_len
;

-- Set rcost_len same as cost_len
UPDATE
    openroads.roadlinks
SET rcost_len = cost_len
;

-- update the speed_mph column with average speeds for each road type. These are my initial values
-- based on function and formofway type. You can set these to whatever you like.
UPDATE
    openroads.roadlinks
SET speed_mph =
    CASE
        WHEN function     = 'A Road'
            AND formofway = 'Single Carriageway'
            THEN 45
        WHEN function     = 'A Road'
            AND formofway = 'Dual Carriageway'
            THEN 50
        WHEN function     = 'A Road'
            AND formofway = 'Collapsed Dual Carriageway'
            THEN 50
        WHEN function     = 'A Road'
            AND formofway = 'Slip Road'
            THEN 40
        WHEN function     = 'B Road'
            AND formofway = 'Single Carriageway'
            THEN 40
        WHEN function     = 'B Road'
            AND formofway = 'Dual Carriageway'
            THEN 45
        WHEN function     = 'B Road'
            AND formofway = 'Collapsed Dual Carriageway'
            THEN 45
        WHEN function     = 'B Road'
            AND formofway = 'Slip Road'
            THEN 30
        WHEN function     = 'Motorway'
            AND formofway = 'Single Carriageway'
            THEN 65
        WHEN function     = 'Motorway'
            AND formofway = 'Dual Carriageway'
            THEN 65
        WHEN function     = 'Motorway'
            AND formofway = 'Collapsed Dual Carriageway'
            THEN 65
        WHEN function     = 'Motorway'
            AND formofway = 'Slip Road'
            THEN 50
        WHEN function      = 'Minor Road'
            AND formofway != 'Roundabout'
            THEN 30
        WHEN function      = 'Local Road'
            AND formofway != 'Roundabout'
            THEN 25
        WHEN function      = 'Local Access Road'
            AND formofway != 'Roundabout'
            THEN 20
        WHEN function      = 'Restricted Local Access Road'
            AND formofway != 'Roundabout'
            THEN 20
        WHEN function      = 'Secondary Access Road'
            AND formofway != 'Roundabout'
            THEN 15
        WHEN formofway = 'Roundabout'
            THEN 10
            ELSE 1
    END
;

-- calculate the cost_time field - here I have calculated estimated journey time in minutes for each link
UPDATE
    openroads.roadlinks
SET cost_time = ( cost_len / 1000.0 / ( speed_mph * 1.609344 ) ) * 60 :: NUMERIC
;

-- Populate coordinates of the start and end points of the links (required by the ASTAR function).
ALTER TABLE openroads.roadlinks ADD COLUMN x1 DOUBLE PRECISION,
    ADD COLUMN y1 DOUBLE PRECISION                            ,
    ADD COLUMN x2 DOUBLE PRECISION                            ,
    ADD COLUMN y2 DOUBLE PRECISION
;

UPDATE
    openroads.roadlinks
SET x1 = st_x ( st_startpoint ( the_geom ) ),
    y1 = st_y ( st_startpoint ( the_geom ) ),
    x2 = st_x ( st_endpoint ( the_geom ) )  ,
    y2 = st_y ( st_endpoint ( the_geom ) )
;

-- create indexes for source and target columns
CREATE INDEX roadlinks_source_idx
ON
    openroads.roadlinks
USING btree
    (
        SOURCE
    )
;

CREATE INDEX roadlinks_target_idx
ON
    openroads.roadlinks
USING btree
    (
        target
    )
;

-- index id
CREATE INDEX roadlinks_id_idx
ON
    openroads.roadlinks
USING btree
    (
        ID
    )
;

-- spatial index
CREATE INDEX roadlinks_the_geom_idx
ON
    openroads.roadlinks
USING gist
    (
        the_geom
    )
;

-- cluster based on roadlinks_the_geom_idx to improve routing performance
-- see http://revenant.ca/www/postgis/workshop/indexing.html
CLUSTER openroads.roadlinks using roadlinks_the_geom_idx;
-- clean-up the table
VACUUM ( ANALYZE, VERBOSE ) openroads.roadlinks;