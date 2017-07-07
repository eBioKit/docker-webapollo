############################################################
# Dockerfile to build WebApollo container image for the eBioKit
# Based on tomcat:8-jre8
# Version 0.1 June 2017
# TODO LIST:
# - Clean data to reduce image size
############################################################

# Set the base image to tomcat:8-jre8
FROM tomcat:8-jre8

# File Maintainer
MAINTAINER Rafael Hernandez <ebiokit@gmail.com>

################## BEGIN INSTALLATION ######################
ENV DEBIAN_FRONTEND=noninteractive CATALINA_HOME=/usr/local/tomcat/ WEBAPOLLO_VERSION=7b304aac81f7dab77165f37bf210a6b3cb1b8080

#INSTALL THE DEPENDENCIES
RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install \
	git build-essential maven tomcat8 libpq-dev postgresql-common openjdk-8-jdk wget \
	postgresql-client xmlstarlet netcat libpng12-dev \
	zlib1g-dev libexpat1-dev ant curl ssl-cert

#INSTALL NODEJS AND FIX DEPENDENCIES
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install nodejs && \
	apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#INSTALL BOWER, FIX SOM JAVA BINARIES AND ADD NEW USER apollo
RUN npm install -g bower && \
	cp /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/tools.jar && \
	useradd -ms /bin/bash -d /apollo apollo

#DOWNLOAD WEBAPOLLO AND chado SCHEMA, EXTRACT THE SOURCES
RUN curl -L https://github.com/GMOD/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | tar xzf - --strip-components=1 -C /apollo && \
	wget --quiet https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins97/chado-1.31.sql.gz -O /chado.sql.gz && \
	gunzip /chado.sql.gz

#ADD FILES AND SET PERMISSIONS
COPY config/launch.sh /bin/
COPY config/apollo-config.groovy config/build.sh /apollo/
RUN chown -R apollo:apollo /apollo

#BUILD THE APOLLO SOURCES
USER apollo
RUN /bin/bash /apollo/build.sh

USER root
RUN rm -rf ${CATALINA_HOME}/webapps/* && \
	mv /apollo/target/apollo*.war ${CATALINA_HOME}/webapps/ROOT.war
	## && \
	##rm -rf /apollo


##################### INSTALLATION END #####################

VOLUME ["/data"]

EXPOSE 8080

ENTRYPOINT ["/bin/launch.sh"]
