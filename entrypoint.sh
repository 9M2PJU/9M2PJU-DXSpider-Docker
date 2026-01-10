# Added ttyd for sysop console over web
# Add configuration update for mysql / mariadb connection

SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}

# generate config file using parameters passed via environment variables
[ ! -f  ${SPIDER_INSTALL_DIR}/local/Listeners.pm -o "${OVERWRITE_CONFIG}" = "yes" ] && \
cat << EOF > ${SPIDER_INSTALL_DIR}/local/Listeners.pm
package main;

use vars qw(@listen);

@listen = (
    ["0.0.0.0", ${CLUSTER_PORT:-7300}],
);

1;
EOF

# call signs and locator should be all upper case
CLUSTER_CALLSIGN=$(echo ${CLUSTER_CALLSIGN} | tr '[a-z]' '[A-Z]')
CLUSTER_SYSOP_CALLSIGN=$(echo ${CLUSTER_SYSOP_CALLSIGN} | tr '[a-z]' '[A-Z]')
CLUSTER_LOCATOR=$(echo ${CLUSTER_LOCATOR} | tr '[a-z]' '[A-Z]')

# escape e-mail addresses to avoid Perl warnings
CLUSTER_SYSOP_EMAIL=$(echo ${CLUSTER_SYSOP_EMAIL} | sed 's/\@/\\\\@/g')
CLUSTER_SYSOP_BBS_ADDRESS=$(echo ${CLUSTER_SYSOP_BBS_ADDRESS} | sed 's/\@/\\\\@/g')

[ ! -f  ${SPIDER_INSTALL_DIR}/local/DXVars.pm -o "${OVERWRITE_CONFIG}" = "yes" ] && \
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

# Remove leading# 
sed -i "/\$dsn/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
sed -i "/\$dbuser/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
sed -i "/\$dbpass/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
sed -i "/\$Internet::contest_host/s/'//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm

# clean stale lock file
[ -f ${SPIDER_INSTALL_DIR}/local/cluster.lck ] && rm -f ${SPIDER_INSTALL_DIR}/local/cluster.lck

# Mojo has another lck file location
[ -f ${SPIDER_INSTALL_DIR}/local_data/cluster.lck ] && rm -f ${SPIDER_INSTALL_DIR}/local_data/cluster.lck


cd ${SPIDER_INSTALL_DIR}/perl && \
./create_sysop.pl && \
./cluster.pl &

sleep 3

ttyd -p ${CLUSTER_SYSOP_PORT} -u 1000 -t fontSize=16 -c ${CLUSTER_DBUSER}:${CLUSTER_DBPASS} perl /spider/perl/console.pl
