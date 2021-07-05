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
