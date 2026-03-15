#!/bin/bash

SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}

# Fix permissions for mounted volumes at runtime
chown -R sysop:sysop ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_data 2>/dev/null

# Generate Listeners.pm
if [ ! -f ${SPIDER_INSTALL_DIR}/local/Listeners.pm ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
cat << EOF > ${SPIDER_INSTALL_DIR}/local/Listeners.pm
package main;
use vars qw(@listen);
@listen = (
    ["0.0.0.0", ${CLUSTER_PORT:-7300}],
);
1;
EOF
fi

# Signal handling for graceful shutdown
function cleanup() {
    echo "Stopping DXSpider Cluster..."
    pkill -f "cluster.pl"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Format calls and locator
CLUSTER_CALLSIGN=$(echo ${CLUSTER_CALLSIGN} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_CALLSIGN=$(echo ${CLUSTER_SYSOP_CALLSIGN} | tr '[a-z]' '[A-Z]')
CLUSTER_LOCATOR=$(echo ${CLUSTER_LOCATOR} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_EMAIL=$(echo ${CLUSTER_SYSOP_EMAIL} | sed 's/@/\\@/g')
CLUSTER_SYSOP_BBS_ADDRESS=$(echo ${CLUSTER_SYSOP_BBS_ADDRESS} | sed 's/@/\\@/g')

# Web Console Credentials (fallback to DB credentials for compatibility)
WEB_USER=${WEB_USER:-${CLUSTER_DBUSER}}
WEB_PASS=${WEB_PASS:-${CLUSTER_DBPASS}}

# Generate DXVars.pm
if [ ! -f ${SPIDER_INSTALL_DIR}/local/DXVars.pm ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
    sed -e "s/\(\$mycall[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_CALLSIGN}\";/" \
        -e "s/\(\$myname[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_NAME}\";/" \
        -e "s/\(\$myalias[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_CALLSIGN}\";/" \
        -e "s/\(\$mylatitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LATITUDE:-0}\";/" \
        -e "s/\(\$mylongitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LONGITUDE:-0}\";/" \
        -e "s/\(\$myqth[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_QTH}\";/" \
        -e "s/\(\$mylocator[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LOCATOR}\";/" \
        -e "s/\(\$myemail[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_EMAIL}\";/" \
        -e "s/\(\$mybbsaddr[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_BBS_ADDRESS}\";/" \
        -e "s/\(\#\$dsn[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DSN}\";/" \
        -e "s/\(\#\$dbuser[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBUSER}\";/" \
        -e "s/\(\#\$dbpass[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBPASS}\";/" \
       < ${SPIDER_INSTALL_DIR}/perl/DXVars.pm.issue > ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    
    sed -i "/\$dsn/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    sed -i "/\$dbuser/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    sed -i "/\$dbpass/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
fi

# Clean lock files
rm -f ${SPIDER_INSTALL_DIR}/local/cluster.lck 2>/dev/null
rm -f ${SPIDER_INSTALL_DIR}/local_data/cluster.lck 2>/dev/null

cd ${SPIDER_INSTALL_DIR}/perl

# Switch to sysop user for execution
su-exec sysop ./create_sysop.pl

echo "Starting DXSpider Cluster..."
su-exec sysop ./cluster.pl &

# Give it a moment to start and check if process exists
sleep 5
if ! pgrep -f "cluster.pl" > /dev/null; then
    echo "FATAL: Cluster failed to start. Check your Perl dependencies."
    exit 1
fi

echo "Starting Web Console..."
# Run ttyd as foreground process
ttyd -p ${CLUSTER_SYSOP_PORT:-8080} -u 1000 -t fontSize=16 -c "${WEB_USER}:${WEB_PASS}" perl /spider/perl/console.pl &

# Wait for children to handle traps
wait
