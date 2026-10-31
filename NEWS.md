# sdft-docker 2.0.0

## Breaking

* Image hosting moved from Docker Hub to public repo-scoped GHCR:
  `ghcr.io/station-demand-forecasting-tool/sdft-docker/sdft-{db,ui}`
* Image tags use `vX.Y.Z` (first GHCR release: `v2.0.0`)
* Compose no longer embeds passwords; use `.env` from `.env.example` (or Doppler for maintainers)
* DB data directory is a named Compose volume (`pgdata` → `/pgdata`)

## Enhancements

* UI base: `rocker/rstudio:4.6.2` (was 4.1.0)
* DB base: `pgrouting/pgrouting:17-3.5-4.0.1` (was Postgres 12 / pgRouting 3.1)
* GitHub Actions workflow publishes both images to GHCR on `v*` tags and via `workflow_dispatch`
* Dropped obsolete Compose top-level `version:` key

## Data

* Seed data and 2018/19 regional uplifts unchanged in this release (2021 population refresh is a separate track)

# sdft-docker 1.1.1

## Fixes

* Issues with /db/setup.sh:
  - Windows CR LF ^M error
  - added IF NOT EXISTS to all index creation statements.
* Issues with /db/data/stations.stations_load.sql:
  - error in create table command
  - creating index idx_stations_location_geom which already exists causes
  error

# sdft-docker 1.1.0

## Enhancements

* Virtual nodes are now created every 500m on edges > 1km. Previously they were 
created every 1km on edges < 1.5km.

## Data

* OS OpenRoads updated - 10/03/2021
* stations_upload updated with latest station openings
* stations.txt updated with latest station openings

## Fixes

* Issue passing db password to clusters in prepare_stations.R

## Other

* /db docker file - change to version argument for LFS downloads
* Additional comments added to docker-compose
* Now using rocker/rstudio:4.1.0 for ui container


# sdft-docker 1.0

Initial release
