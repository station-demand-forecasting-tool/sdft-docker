# docker build -t "sdft-db" .
# docker run --name sdft-db -p 5432:5432 --env POSTGRES_PASSWORD=password sdft-db:latest
# OR if just to get to bash and not start up PostgreSQL
# docker run -it sdft-db /bin/bash
# if container already running
# THEN:
# docker container exec -it sdft /bin/bash
# send postgres cofig via CMD entrypoint
# docker run --name sdft-db --env POSTGRES_PASSWORD=password sdft-db postgres -c max_wal_size=10GB
# to view sql setup after running docker-compose up -d attach to the container using:
# docker attach  --sig-proxy=false sdft-db
# --sig-proxy=false allows you to use ctrl-c to detach without stopping the container
# On windows you can see progres in the Dashboard - the logs for the container.
# Use ctrl-c to detach 

FROM pgrouting/pgrouting:12-3.0-3.1.0

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && \
	apt-get install -y --assume-yes apt-utils

RUN apt-get update && \
	apt-get install -y \
	sudo \
	curl \
	wget \
	unzip 
	
# need to get the shp2psql and pgsql2shp tools 
RUN apt-get install postgis --no-install-recommends

RUN mkdir /home/sql home/pgrwrappers /home/data

# This is a workaround as Docker Hub doesn't support git-lfs for automated builds. Downloaded the files directly.
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/station-demand-forecasting-tool/sdft-docker/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \ 
 wget --progress=bar:force:noscroll -P /home/data/stations https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/stations/stations_load.sql && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/population/pc_pop_2011.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/population/pc_pop_2011.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/population/pc_pop_2011.prj && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/population/pc_pop_2011.shp && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/population/pc_pop_2011.shx && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/workplace/workplace2011.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/workplace/workplace2011.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/workplace/workplace2011.prj && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/workplace/workplace2011.shp && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/workplace/workplace2011.shx && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/gb/gb_outline.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/gb/gb_outline.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/gb/gb_outline.prj && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/gb/gb_outline.shp && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/data/gb/gb_outline.shx && \
 wget --progress=bar:force:noscroll -P /home/ https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/v${LATEST_VERSION}/db/oproad_essh_gb.zip

COPY /sql /home/sql
COPY /data/stations/stations.csv /home/data/stations/
COPY /data/uplifts/regional_uplifts.csv /home/data/uplifts/
COPY /data/hhsize/hhsize.csv /home/data/hhsize/
COPY /pgrwrappers /home/pgrwrappers

# Only unzip the /data directory
RUN unzip /home/oproad_essh_gb.zip  'data/*' -d /home/openroads && \
	rm -r /home/oproad_essh_gb.zip

COPY setup.sh /docker-entrypoint-initdb.d/setup.sh

ENV PGDATA=/pgdata

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["postgres"]

# labels
LABEL maintainer="marcus@graspit.co.uk"
