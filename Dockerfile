############################################################
# Dockerfile to build WebApollo container image for the eBioKit
# Based on tomcat:8-jre8
# Version 0.1 June 2017
# TODO LIST:
# - Clean data to reduce image size
############################################################

# Set the base image to tomcat:8-jre8
FROM tomcat:8.5-jre8-alpine

# File Maintainer
MAINTAINER Rafael Hernandez <ebiokit@gmail.com>

################## BEGIN INSTALLATION ######################

#ADD FILES AND SET PERMISSIONS
ENV DEBIAN_FRONTEND=noninteractive CATALINA_HOME=/usr/local/tomcat/ WEBAPOLLO_VERSION=7b304aac81f7dab77165f37bf210a6b3cb1b8080 CONTEXT_PATH=ROOT
COPY config/launch.sh config/build.sh /bin/

#INSTALL THE DEPENDENCIES
RUN apk update && \
	apk add --update tar && \
	apk add curl ca-certificates bash nodejs git postgresql postgresql-client \
		maven libpng make g++ zlib-dev expat-dev nodejs-npm sudo

RUN npm install -g bower && \
	adduser -s /bin/bash -D -h /apollo apollo && \
	curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | \
	tar xzf - --strip-components=1 -C /apollo && \
	chown -R apollo:apollo /apollo

COPY config/apollo-config.groovy /apollo/

RUN apk add openjdk8 openjdk8-jre && \
	cp /usr/lib/jvm/java-1.8-openjdk/lib/tools.jar /usr/lib/jvm/java-1.8-openjdk/jre/lib/ext/tools.jar

RUN curl -o /chado.sql.gz https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins97/chado-1.31.sql.gz

RUN apk del curl bash nodejs git libpng make g++ nodejs-npm openjdk8 sudo


##################### INSTALLATION END #####################

VOLUME ["/data"]

ENTRYPOINT ["/bin/launch.sh"]
