# docker build -t sdft-db --no-cache .

FROM pgrouting/pgrouting:17-3.5-4.0.1

# Base is Debian 11 (bullseye), past LTS (2026-08-31): live mirrors keep bullseye-security
# indexes but .deb pool files 404; use archive.debian.org for security. Also drop stale PGDG.
# Keep postgis apt package for shp2pgsql (setup.sh); the PostGIS extension comes from the base.
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
	echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
	rm -f /etc/apt/sources.list.d/pgdg*.list && \
	for f in /etc/apt/sources.list /etc/apt/sources.list.d/*; do \
		[ -f "$f" ] || continue; \
		sed -i \
			-e 's|https\?://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
			-e 's|https\?://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
			"$f"; \
	done && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
	sudo \
	curl \
	wget \
	unzip \
	postgis \
	&& rm -rf /var/lib/apt/lists/*


# Download LFS-backed seed assets from the latest GitHub release (avoids needing git-lfs in the image build).
# Note: will have to force no-cache if running manually as the following RUN appears always unchanged to Docker.

RUN LATEST_VERSION=v$(curl -s https://api.github.com/repos/station-demand-forecasting-tool/sdft-docker/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
 wget --progress=bar:force:noscroll -P /home/data/stations https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/stations/stations_load.sql && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/population/pc_pop_2011.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/population/pc_pop_2011.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/population/pc_pop_2011.prj && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/population/pc_pop_2011.shp && \
 wget --progress=bar:force:noscroll -P /home/data/population https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/population/pc_pop_2011.shx && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/workplace/workplace2011.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/workplace/workplace2011.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/workplace/workplace2011.prj && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/workplace/workplace2011.shp && \
 wget --progress=bar:force:noscroll -P /home/data/workplace https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/workplace/workplace2011.shx && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/gb/gb_outline.dbf && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/gb/gb_outline.cpg && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/gb/gb_outline.prj && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/gb/gb_outline.shp && \
 wget --progress=bar:force:noscroll -P /home/data/gb https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/data/gb/gb_outline.shx && \
 wget --progress=bar:force:noscroll -P /home/ https://media.githubusercontent.com/media/station-demand-forecasting-tool/sdft-docker/${LATEST_VERSION}/db/oproad_essh_gb.zip

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
LABEL maintainer="m.a.young@soton.ac.uk"
