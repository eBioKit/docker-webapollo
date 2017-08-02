#!/bin/sh
# https://tomcat.apache.org/tomcat-8.0-doc/config/context.html#Naming
FIXED_CTX=$(echo "${CONTEXT_PATH}" | sed 's|/|#|g')
WAR_FILE=${CATALINA_HOME}/webapps/${FIXED_CTX}.war
rm -rf ${CATALINA_HOME}/webapps/*
cp /apollo/apollo.war ${WAR_FILE}

WEBAPOLLO_DB_HOST="${WEBAPOLLO_DB_HOST:-127.0.0.1}"
WEBAPOLLO_DB_NAME="${WEBAPOLLO_DB_NAME:-apollo}"
WEBAPOLLO_DB_USERNAME="${WEBAPOLLO_DB_USERNAME:-apollo}"
WEBAPOLLO_DB_PASSWORD="${WEBAPOLLO_DB_PASSWORD:-apollo}"

WEBAPOLLO_CHADO_DB_HOST="${WEBAPOLLO_CHADO_DB_HOST:-127.0.0.1}"
WEBAPOLLO_CHADO_DB_NAME="${WEBAPOLLO_CHADO_DB_NAME:-chado}"
WEBAPOLLO_CHADO_DB_USERNAME="${WEBAPOLLO_CHADO_DB_USERNAME:-apollo}"
WEBAPOLLO_CHADO_DB_PASSWORD="${WEBAPOLLO_CHADO_DB_PASSWORD:-apollo}"

if [[ "${WEBAPOLLO_DB_HOST}" == "127.0.0.1" ]]; then
	echo "Using internal postgresql service for WebApollo..."
	service postgresql start
else
	echo "Using external postgresql service (${WEBAPOLLO_DB_HOST}) for WebApollo..."
fi

if [[ "${WEBAPOLLO_CHADO_DB_HOST}" == "127.0.0.1" ]]; then
	echo "Using internal postgresql service for Chado..."
	service postgresql start
else
	echo "Using external postgresql service (${WEBAPOLLO_CHADO_DB_HOST}) for Chado..."
fi

echo "Waiting for WebApollo DB"
until pg_isready -h $WEBAPOLLO_DB_HOST -p $WEBAPOLLO_DB_PORT -U $WEBAPOLLO_DB_USERNAME -d $WEBAPOLLO_DB_NAME; do
	echo -n "."
	sleep 5;
done;

echo "Waiting for Chado DB"
until pg_isready -h $WEBAPOLLO_CHADO_DB_HOST -p $WEBAPOLLO_CHADO_DB_PORT -U $WEBAPOLLO_CHADO_DB_USERNAME -d $WEBAPOLLO_CHADO_DB_NAME; do
	echo -n "."
	sleep 5;
done;

su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -lqt | cut -d \| -f 1 | grep -qw ${WEBAPOLLO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Apollo database not found, creating..."
	su postgres -c "createdb ${WEBAPOLLO_HOST_FLAG} ${WEBAPOLLO_DB_NAME}"
	su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -c \"CREATE USER ${WEBAPOLLO_DB_USERNAME} WITH PASSWORD '${WEBAPOLLO_DB_PASSWORD}';\""
	su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${WEBAPOLLO_DB_NAME}\" to ${WEBAPOLLO_DB_USERNAME};'"
fi

su postgres -c "psql ${WEBAPOLLO_CHADO_HOST_FLAG} -lqt | cut -d \| -f 1 | grep -qw ${WEBAPOLLO_CHADO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Chado database not found, creating..."
	su postgres -c "createdb ${WEBAPOLLO_CHADO_HOST_FLAG} ${WEBAPOLLO_CHADO_DB_NAME}"
	su postgres -c "psql ${WEBAPOLLO_CHADO_HOST_FLAG} -c \"CREATE USER ${WEBAPOLLO_CHADO_DB_USERNAME} WITH PASSWORD '${WEBAPOLLO_CHADO_DB_PASSWORD}';\""
	su postgres -c "psql ${WEBAPOLLO_CHADO_HOST_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${WEBAPOLLO_CHADO_DB_NAME}\" to ${WEBAPOLLO_CHADO_DB_USERNAME};'"
	echo "Loading Chado data"
	su postgres -c "PGPASSWORD=${WEBAPOLLO_CHADO_DB_PASSWORD} psql -U ${WEBAPOLLO_CHADO_DB_USERNAME} -h ${WEBAPOLLO_DB_HOST} ${WEBAPOLLO_CHADO_DB_NAME} -f /chado.sql"
fi


catalina.sh run
