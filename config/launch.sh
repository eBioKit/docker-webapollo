#!/bin/sh
# https://tomcat.apache.org/tomcat-8.0-doc/config/context.html#Naming
CONTEXT_PATH="${CONTEXT_PATH:-ROOT}"
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
WEBAPOLLO_DB_CONNECTION_FLAG="-h $WEBAPOLLO_DB_HOST -p $WEBAPOLLO_DB_PORT -U $WEBAPOLLO_DB_USERNAME"
until pg_isready ${WEBAPOLLO_DB_CONNECTION_FLAG} -d $WEBAPOLLO_DB_NAME; do
	echo -n "."
	sleep 5;
done;

echo "Waiting for Chado DB"
WEBAPOLLO_CHADO_DB_CONNECTION_FLAG="-h $WEBAPOLLO_CHADO_DB_HOST -p $WEBAPOLLO_CHADO_DB_PORT -U $WEBAPOLLO_CHADO_DB_USERNAME"
until pg_isready ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} -d $WEBAPOLLO_CHADO_DB_NAME; do
	echo -n "."
	sleep 5;
done;

su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; psql ${WEBAPOLLO_DB_CONNECTION_FLAG}  -lqt | cut -d \| -f 1 | grep -qw ${WEBAPOLLO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Apollo database not found, creating..."
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; createdb ${WEBAPOLLO_DB_CONNECTION_FLAG} ${WEBAPOLLO_DB_NAME}"
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; psql ${WEBAPOLLO_DB_CONNECTION_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${WEBAPOLLO_DB_NAME}\" to ${WEBAPOLLO_DB_USERNAME};'"
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; psql ${WEBAPOLLO_DB_CONNECTION_FLAG} -c \"CREATE USER ${WEBAPOLLO_DB_USERNAME} WITH PASSWORD '${WEBAPOLLO_DB_PASSWORD}';\""
else
	echo "Apollo database already exists."
fi

su postgres -c "export PGPASSWORD='${WEBAPOLLO_CHADO_DB_PASSWORD}'; psql ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} -lqt | cut -d \| -f 1 | grep -qw ${WEBAPOLLO_CHADO_DB_NAME}"
if [[ "$?" == "1" ]]; then
	echo "Chado database not found, creating..."
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; createdb ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} ${WEBAPOLLO_CHADO_DB_NAME}"
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; psql ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} -c \"CREATE USER ${WEBAPOLLO_CHADO_DB_USERNAME} WITH PASSWORD '${WEBAPOLLO_CHADO_DB_PASSWORD}';\""
	su postgres -c "export PGPASSWORD='${WEBAPOLLO_DB_PASSWORD}'; psql ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} -c 'GRANT ALL PRIVILEGES ON DATABASE \"${WEBAPOLLO_CHADO_DB_NAME}\" to ${WEBAPOLLO_CHADO_DB_USERNAME};'"
else
	echo "Chado database already exists."
fi

su postgres -c "export PGPASSWORD=${WEBAPOLLO_CHADO_DB_PASSWORD}; psql ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} ${WEBAPOLLO_CHADO_DB_NAME} -c'\dt' | grep -c table"
if [[ "$?" != "0" ]]; then
	echo "Loading Chado data"
	gunzip -c /chado.sql.gz > /tmp/chado.sql
	su postgres -c "export PGPASSWORD=${WEBAPOLLO_CHADO_DB_PASSWORD}; psql ${WEBAPOLLO_CHADO_DB_CONNECTION_FLAG} ${WEBAPOLLO_CHADO_DB_NAME} -f /tmp/chado.sql"
	rm /tmp/chado.sql
else
	echo "Chado database is already populated."
fi

echo "Restarting tomcat with $CATALINA_HOME"
${CATALINA_HOME}/bin/shutdown.sh
${CATALINA_HOME}/bin/startup.sh

touch ${CATALINA_HOME}/logs/catalina.out
tail -f ${CATALINA_HOME}/logs/catalina.out
