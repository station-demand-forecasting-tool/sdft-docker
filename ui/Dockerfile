# docker build -t "sdft-ui" .
# docker run --name sdft-ui -it sdft-ui
# if container already running
# THEN:
# docker container exec -it sdft-ui R
# OR for bash
# docker container exec -it sdft-ui /bin/bash
# docker tag sdft-ui sdft/sdft-ui:latest
# docker login
# docker push sdft/sdft-ui:latest


FROM rocker/rstudio:4.0.2

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && \
	apt-get install -y --assume-yes apt-utils

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	sudo \
	unzip \
	wget \
	libssl-dev \
	libsodium-dev \
	libpq-dev \
	libsecret-1-dev 
	
RUN mkdir /home/r

COPY /r /home/r

RUN wget https://github.com/station-demand-forecasting-tool/sdft/archive/master.zip -P tmp && \
	Rscript /home/r/setup.R

EXPOSE 8787/tcp


# labels
LABEL maintainer="marcus@graspit.co.uk"
