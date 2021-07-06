#!/bin/bash

# This for local image generation only:
# if the stations variable is set to "create" then the station table will be generated from the stations.csv file
# and, once the database has been built on the sdft-db container, the
# prepare_stations.R script must be run from the sdft-ui container to generate the service areas for each station.
# The stations table can then be exported to a SQL file and used to generate a new public container image.
# We cannot use a shapefile for this export/import as there are multiple geometries in the stations table.
# stations="create"
stations="load"

set -e

psql --username "postgres" -f /home/sql/setup.sql

#prepare the tables don't load data -p  Prepare mode, only creates the table.
#force non-multi and set the geometry column name to the_geom, dbf is in latin1 encoding


shp2pgsql -s 27700 -g the_geom -S -p /home/openroads/data/HP_RoadLink.shp openroads.roadlinks | psql -U postgres -d dafni


F1=/home/openroads/data/*RoadLink.shp
for f in $F1
do
	shp2pgsql -s 27700 -g the_geom -S -a -D $f "openroads"."roadlinks" | psql -U postgres -d dafni
done


shp2pgsql -s 27700 -g the_geom -S -p /home/openroads/data/HP_RoadNode.shp openroads.roadnodes | psql -U postgres -d dafni


F2=/home/openroads/data/*RoadNode.shp
for g in $F2
do
	shp2pgsql -s 27700 -g the_geom -S -a -D $g "openroads"."roadnodes" | psql -U postgres -d dafni
done

psql --username "postgres" -d dafni -f /home/sql/openroads.sql

psql --username "postgres" -d dafni -f /home/sql/disconnected.sql

psql --username "postgres" -d dafni -f /home/sql/virtualnodes.sql


# load pc_pop_2011 shapefile

f=/home/data/population/pc_pop_2011.shp

shp2pgsql -s 27700 -g geom -S -D $f "data"."pc_pop_2011" | psql -U postgres -d dafni

psql --username "postgres" -d dafni -c 'alter table data.pc_pop_2011 drop column id;'
psql --username "postgres" -d dafni -c 'alter table data.pc_pop_2011 rename column gid to id;'
psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_pc_pop_2011_geom on data.pc_pop_2011 using gist ( geom );'
psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_pc_pop_2011_postcode on data.pc_pop_2011 using btree ( postcode );'

# decision whether to load stations shapefile with service areas
# or whether to recreate stations table

if [ $stations = "create" ]
then
echo "create new stations table from stations.csv"
psql --username "postgres" -d dafni -f /home/sql/stations.sql
else
echo "Load existing stations sql file"
psql --username "postgres" -d dafni -f /home/data/stations/stations_load.sql
fi

psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_stations_location_geom on data.stations using gist ( location_geom );'


f=/home/data/workplace/workplace2011.shp
shp2pgsql -s 27700 -g geom -S -D $f "data"."workplace2011" | psql -U postgres -d dafni

psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_workplace2011_geom on data.workplace2011 using gist ( geom );'
psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_workplace2011_wz on data.workplace2011 using btree ( wz );'

psql --username "postgres" -d dafni -f /home/sql/hhsize.sql

f=/home/data/gb/gb_outline.shp
shp2pgsql -s 27700 -g geom -D $f "data"."gb_outline" | psql -U postgres -d dafni

psql --username "postgres" -d dafni -c 'create index IF NOT EXISTS idx_gb_outline_geom on data.gb_outline using gist ( geom );'


psql --username "postgres" -d dafni -f /home/sql/uplifts.sql

psql --username "postgres" -d dafni -f /home/pgrwrappers/function_pgr_pointtoedgenode.sql
psql --username "postgres" -d dafni -f /home/pgrwrappers/function_bbox_pgr_withpointscost.sql
psql --username "postgres" -d dafni -f /home/pgrwrappers/function_create_pgr_vnodes.sql
psql --username "postgres" -d dafni -f /home/pgrwrappers/function_sdr_crs_pc_nearest_stationswithpoints.sql
psql --username "postgres" -d dafni -f /home/pgrwrappers/function_sdr_pc_station_withpoints.sql
psql --username "postgres" -d dafni -f /home/pgrwrappers/function_sdr_pc_station_withpoints_nobbox.sql

echo "creating centroidnodes table. This will take some time ..."
psql --username "postgres" -d dafni -f /home/sql/centroidnodes.sql





