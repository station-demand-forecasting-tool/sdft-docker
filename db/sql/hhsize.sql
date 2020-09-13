DROP TABLE IF EXISTS "data"."hhsize";
CREATE TABLE "data"."hhsize" (
  "id" SERIAL PRIMARY KEY,
  "area_code" text,
  "avg_hhsize_2019" float8
)
;

-- import latest stations CSV file

COPY data.hhsize(area_code, avg_hhsize_2019)
FROM '/home/data/hhsize/hhsize.csv'
DELIMITER ','
CSV HEADER;