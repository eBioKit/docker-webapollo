#!/bin/bash

WEBAPOLLO_DB_HOST="${WEBAPOLLO_DB_HOST:-127.0.0.1}"
WEBAPOLLO_DB_NAME="${WEBAPOLLO_DB_NAME:-apollo}"
WEBAPOLLO_DB_USERNAME="${WEBAPOLLO_DB_USERNAME:-apollo}"
WEBAPOLLO_DB_PASSWORD="${WEBAPOLLO_DB_PASSWORD:-apollo}"


# TODO: use variable throughout
#USE_CHADO="${USE_CHADO:true}"
CHADO_DB_HOST="${CHADO_DB_HOST:-127.0.0.1}"
CHADO_DB_NAME="${CHADO_DB_NAME:-chado}"
CHADO_DB_USERNAME="${CHADO_DB_USERNAME:-apollo}"
CHADO_DB_PASSWORD="${CHADO_DB_PASSWORD:-apollo}"

if [[ "${WEBAPOLLO_DB_HOST}" == "127.0.0.1" ]]; then
	echo "Using internal postgresql service for WebApollo..."
	service postgresql start
else
	echo "Using external postgresql service (${WEBAPOLLO_DB_HOST}) for WebApollo..."
	WEBAPOLLO_HOST_FLAG="-h ${WEBAPOLLO_DB_HOST}"
fi

if [[ "${CHADO_DB_HOST}" == "127.0.0.1" ]]; then
	echo "Using internal postgresql service for Chado..."
	service postgresql start
else
	echo "Using external postgresql service (${CHADO_DB_HOST}) for Chado..."
	CHADO_HOST_FLAG="-h ${CHADO_DB_HOST}"
fi

echo "Waiting for WebApollo DB"
until pg_isready ${WEBAPOLLO_HOST_FLAG}; do
	echo -n "."
	sleep 5;
done
echo "Postgres is up..."

su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -lqt | cut -d \| -f 1 | grep -qw ${WEBAPOLLO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Apollo database not found, creating..."
	su postgres -c "createdb ${WEBAPOLLO_HOST_FLAG} ${WEBAPOLLO_DB_NAME}"
	su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -c \"CREATE USER ${WEBAPOLLO_DB_USERNAME} WITH PASSWORD '${WEBAPOLLO_DB_PASSWORD}';\""
	su postgres -c "psql ${WEBAPOLLO_HOST_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${WEBAPOLLO_DB_NAME}\" to ${WEBAPOLLO_DB_USERNAME};'"
fi

su postgres -c "psql ${CHADO_HOST_FLAG} -lqt | cut -d \| -f 1 | grep -qw ${CHADO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Chado database not found, creating..."
	su postgres -c "createdb ${CHADO_HOST_FLAG} ${CHADO_DB_NAME}"
	su postgres -c "psql ${CHADO_HOST_FLAG} -c \"CREATE USER ${CHADO_DB_USERNAME} WITH PASSWORD '${CHADO_DB_PASSWORD}';\""
	su postgres -c "psql ${CHADO_HOST_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${CHADO_DB_NAME}\" to ${CHADO_DB_USERNAME};'"
	echo "Loading Chado data"
	su postgres -c "PGPASSWORD=${CHADO_DB_PASSWORD} psql -U ${CHADO_DB_USERNAME} -h ${WEBAPOLLO_DB_HOST} ${CHADO_DB_NAME} -f /chado.sql"
fi

echo "Restarting tomcat with $CATALINA_HOME"
${CATALINA_HOME}/bin/shutdown.sh
${CATALINA_HOME}/bin/startup.sh

touch ${CATALINA_HOME}/logs/catalina.out
tail -f ${CATALINA_HOME}/logs/catalina.out
