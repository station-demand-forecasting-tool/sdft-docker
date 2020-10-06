# docker build -t "sdft-ui" .
# docker run --name sdft-ui -it sdft-ui
# if container is already running
# THEN:
# docker container exec -it sdft-ui R
# OR for bash
# docker container exec -it sdft-ui /bin/bash
# docker tag sdft-ui sdft/sdft-ui:latest
# docker login
# docker push sdft/sdft-ui:latest


FROM rocker/rstudio:4.0.2

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
	apt-get install -y --no-install-recommends \
	sudo \
	unzip \
	curl \
	libssl-dev \
	libsodium-dev \
	libpq-dev \
	libsecret-1-dev \
	&& rm -rf /var/lib/apt/lists/*
	
# RUN mkdir /home/r

COPY /r /home/r

# download the latest release of sdft and then run R setup
# must build with --no-cache as this RUN statement will not change between sdft versions
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/station-demand-forecasting-tool/sdft/releases/latest | grep "tag_name" | cut -d'v' -f2 | cut -d'"' -f1) && \
	curl -L -o /tmp/sdft.zip https://github.com/station-demand-forecasting-tool/sdft/archive/v${LATEST_VERSION}.zip && \
	unzip /tmp/sdft.zip -d /tmp && \
	mv /tmp/sdft-* /tmp/sdft && \
	Rscript /home/r/setup.R

EXPOSE 8787/tcp


# labels
LABEL maintainer="marcus@graspit.co.uk"
