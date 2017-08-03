#!/bin/bash
set -ex
# Doubly set, because reasons.
export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre

cd /apollo/ && \
	./apollo deploy && \
	./apollo deploy && \
	#./install_jbrowse.sh && \
	# Move to tmp dir
	cp /apollo/target/apollo*.war /tmp/apollo.war && \
	# Move all the perl modules
	#mv /apollo/extlib/ /extlib/ && \
	# So we can remove ~1.6 GB of cruft from the image. Ignore errors because cannot remove parent dir /apollo/
	rm -rf /apollo/ || true && \
	# Before moving back into a standardized location (that we have write access to)
	mv /tmp/apollo.war /apollo/apollo.war

if [ -d /output/ ]; then
	cp /apollo/apollo.war /output/;
fi
