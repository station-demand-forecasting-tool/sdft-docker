# docker build -t sdft-ui --no-cache .

FROM rocker/rstudio:4.1.0

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

# set required sdft R package release
# if this is updated then issue a new release of sdft-docker
# this will then trigger automated build on Docker Hub

ARG sdft=0.3.2

# download the specified release of sdft and then run R setup
RUN SDFT_VERSION=v$sdft && \
	curl -L -o /tmp/sdft.zip https://github.com/station-demand-forecasting-tool/sdft/archive/${SDFT_VERSION}.zip && \
	unzip /tmp/sdft.zip -d /tmp && \
	mv /tmp/sdft-* /tmp/sdft && \
	Rscript /home/r/setup.R

EXPOSE 8787/tcp


# labels
LABEL maintainer="marcus@graspit.co.uk"
