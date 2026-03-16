#!/bin/bash

SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
SPIDER_UID=${SPIDER_UID:-1000}
SPIDER_GROUP=${SPIDER_USERNAME}


# Fix permissions for mounted volumes at runtime
chown -R ${SPIDER_USERNAME}:${SPIDER_GROUP} ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_data 2>/dev/null

# Ensure persistence for critical data by symlinking to local_data
# This covers spot logs, cluster logs, and debug data
for dir in log spots debug; do
    mkdir -p ${SPIDER_INSTALL_DIR}/local_data/${dir}
    # If the internal data dir is a real directory, move its content to local_data first
    if [ -d ${SPIDER_INSTALL_DIR}/data/${dir} ] && [ ! -L ${SPIDER_INSTALL_DIR}/data/${dir} ]; then
        cp -an ${SPIDER_INSTALL_DIR}/data/${dir}/. ${SPIDER_INSTALL_DIR}/local_data/${dir}/ 2>/dev/null
        rm -rf ${SPIDER_INSTALL_DIR}/data/${dir}
    fi
    # Link internal data dir to persistent local_data
    ln -sf ${SPIDER_INSTALL_DIR}/local_data/${dir} ${SPIDER_INSTALL_DIR}/data/${dir}
    chown -R ${SPIDER_USERNAME}:${SPIDER_GROUP} ${SPIDER_INSTALL_DIR}/local_data/${dir}
done


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

# Format calls and locator with robust defaults
CLUSTER_CALLSIGN=$(echo ${CLUSTER_CALLSIGN:-GB7DJK} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_CALLSIGN=$(echo ${CLUSTER_SYSOP_CALLSIGN:-G1TLH} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_NAME=${CLUSTER_SYSOP_NAME:-"DXSpider Sysop"}
CLUSTER_QTH=${CLUSTER_QTH:-"DXSpider Node"}
CLUSTER_LOCATOR=$(echo ${CLUSTER_LOCATOR:-JO01aa} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_EMAIL=$(echo ${CLUSTER_SYSOP_EMAIL:-"sysop@localhost"} | sed 's/@/\\@/g')
CLUSTER_SYSOP_BBS_ADDRESS=$(echo ${CLUSTER_SYSOP_BBS_ADDRESS:-"bbs@localhost"} | sed 's/@/\\@/g')

# Web Console Credentials (fallback to DB credentials or 'sysop' for compatibility)
WEB_USER=${WEB_USER:-${CLUSTER_DBUSER:-sysop}}
WEB_PASS=${WEB_PASS:-${CLUSTER_DBPASS:-sysoppassword}}


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
su-exec ${SPIDER_USERNAME} ./create_sysop.pl

echo "Starting DXSpider Cluster..."
su-exec ${SPIDER_USERNAME} ./cluster.pl &

# Give it a moment to start and check if process exists
sleep 5
if ! pgrep -f "cluster.pl" > /dev/null; then
    echo "FATAL: Cluster failed to start. Check your Perl dependencies."
    exit 1
fi

echo "Starting Web Console..."
# Run ttyd as foreground process
ttyd -p ${CLUSTER_SYSOP_PORT:-8080} -u ${SPIDER_UID} -t fontSize=16 -W -c "${WEB_USER}:${WEB_PASS}" perl ${SPIDER_INSTALL_DIR}/perl/console.pl &


# Wait for children to handle traps
wait
