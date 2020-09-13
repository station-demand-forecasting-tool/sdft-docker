SET datestyle = 'ISO,DMY';

DROP TABLE IF EXISTS "data"."stations";
CREATE TABLE "data"."stations" (
  "id" SERIAL PRIMARY KEY,
  "crscode" text,
  "name" text,
  "longitude" text,
  "latitude" text,
  "easting" int4,
  "northing" int4,
  "staffinglevel" text,
  "cctv" text,
  "ticketmachine" text,
  "carspaces" int4,
  "busservices" text,
  "category" text,
  "frequency" int4,
  "entsexits" int4,
  "dateopened" date
)
;

-- import latest stations CSV file

COPY data.stations(crscode, name, longitude, latitude, easting, northing, staffinglevel, cctv, ticketmachine, carspaces, busservices, category, frequency, entsexits, dateopened)
FROM '/home/data/stations/stations.csv'
DELIMITER ','
CSV HEADER;

-- create location geom

alter table data.stations ADD COLUMN location_geom geometry(Point,27700);

update data.stations
set location_geom = ST_GeomFromText('POINT('||easting||' '||northing||')', 27700)

-- create service areas

