# docker build -t "sdft-db" .
# docker run --name sdft-db -p 5432:5432 --env POSTGRES_PASSWORD=password sdft:latest
# OR if just to get to bash and not strat up PostgreSQL
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
	unzip 
	
# need to get the shp2psql and pgsql2shp tools 
RUN apt-get install postgis --no-install-recommends

RUN mkdir /home/sql home/pgrwrappers /home/data

COPY /sql /home/sql
COPY /data /home/data
COPY /pgrwrappers /home/pgrwrappers
COPY oproad_essh_gb.zip /home

# Only unzip the /data directory
RUN unzip /home/oproad_essh_gb.zip  'data/*' -d /home/openroads && \
	rm -r /home/oproad_essh_gb.zip

COPY setup.sh /docker-entrypoint-initdb.d/setup.sh

ENV PGDATA=/pgdata

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["postgres"]

# labels
LABEL maintainer="marcus@graspit.co.uk"
