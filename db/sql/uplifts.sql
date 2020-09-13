DROP TABLE IF EXISTS "data"."regional_uplifts";
CREATE TABLE "data"."regional_uplifts" (
  "id" SERIAL PRIMARY KEY,
  "region" text,
  "total112" float8,
  "total819" float8,
  "pcchange" float8
)
;

-- import latest stations CSV file

COPY data.regional_uplifts(region, total112, total819, pcchange)
FROM '/home/data/uplifts/regional_uplifts.csv'
DELIMITER ','
CSV HEADER;