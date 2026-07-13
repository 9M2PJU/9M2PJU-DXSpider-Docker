#!/bin/bash
# =============================================================================
#  DXSpider Docker — Container Entrypoint
#
#  Responsibilities (in order):
#    1. Fix ownership of bind-mounted volumes (runs as root)
#    2. Symlink internal data dirs to persistent local_data
#    3. Generate Listeners.pm (telnet listen address/port)
#    4. Generate DXVars.pm (cluster identity, location, optional DB)
#    5. Clean stale lock files from previous runs
#    6. Create/update the sysop user in the DXSpider user database
#    7. Start cluster.pl as the sysop user (via su-exec)
#    8. Start the ttyd web console (drops to sysop UID for console.pl)
#    9. Wait for children and forward signals for graceful shutdown
#
#  set -euo pipefail: fail on errors, undefined vars, and pipe failures
# =============================================================================
set -euo pipefail

# --- Resolve runtime configuration with safe defaults ---
SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
SPIDER_UID=${SPIDER_UID:-1000}
SPIDER_GROUP=${SPIDER_USERNAME}

# =============================================================================
#  Step 1: Fix permissions on bind-mounted volumes
#
#  Bind mounts inherit the host's UID/GID, which may not match the sysop
#  user inside the container. We chown them here (running as root) so
#  the cluster can read/write its data after dropping privileges.
#  Errors are non-fatal (e.g., read-only mounts).
# =============================================================================
chown -R ${SPIDER_USERNAME}:${SPIDER_GROUP} \
    ${SPIDER_INSTALL_DIR}/local \
    ${SPIDER_INSTALL_DIR}/local_data 2>/dev/null || true

# =============================================================================
#  Step 2: Symlink internal data dirs to persistent local_data
#
#  DXSpider writes logs, spots, and debug data to /spider/data/{log,spots,debug}.
#  We redirect these to /spider/local_data/{log,spots,debug} (which is a
#  bind-mounted volume) so the data survives container recreation.
#  If the internal dir already has content (first run), copy it out first.
# =============================================================================
for dir in log spots debug; do
    mkdir -p ${SPIDER_INSTALL_DIR}/local_data/${dir}
    # If the internal data dir is a real directory (not yet a symlink),
    # copy its contents to local_data before replacing it with a symlink
    if [ -d ${SPIDER_INSTALL_DIR}/data/${dir} ] && [ ! -L ${SPIDER_INSTALL_DIR}/data/${dir} ]; then
        cp -an ${SPIDER_INSTALL_DIR}/data/${dir}/. ${SPIDER_INSTALL_DIR}/local_data/${dir}/ 2>/dev/null || true
        rm -rf ${SPIDER_INSTALL_DIR}/data/${dir}
    fi
    # Create the symlink: /spider/data/<dir> → /spider/local_data/<dir>
    ln -sf ${SPIDER_INSTALL_DIR}/local_data/${dir} ${SPIDER_INSTALL_DIR}/data/${dir}
    chown -R ${SPIDER_USERNAME}:${SPIDER_GROUP} ${SPIDER_INSTALL_DIR}/local_data/${dir}
done

# =============================================================================
#  Step 3: Generate Listeners.pm (telnet listen configuration)
#
#  Only generated if missing, unless OVERWRITE_CONFIG=yes forces regeneration.
#  This tells DXSpider which address/port to listen on for user telnet.
# =============================================================================
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

# =============================================================================
#  Step 4 (signal handler): Graceful shutdown on SIGTERM / SIGINT
#
#  Docker sends SIGTERM on `docker stop`. We kill both the cluster and
#  the web console so the container exits cleanly.
# =============================================================================
function cleanup() {
    echo "Stopping DXSpider Cluster..."
    pkill -f "cluster.pl" 2>/dev/null || true
    pkill -f "ttyd" 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# =============================================================================
#  Step 5: Normalize cluster identity values
#
#  Callsigns and grid locators must be uppercase for DXSpider.
#  Email/BBS addresses need @ escaped for Perl string literals.
#  All values fall back to upstream DXSpider defaults if unset.
# =============================================================================
CLUSTER_CALLSIGN=$(echo "${CLUSTER_CALLSIGN:-GB7DJK}" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_CALLSIGN=$(echo "${CLUSTER_SYSOP_CALLSIGN:-G1TLH}" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_NAME=${CLUSTER_SYSOP_NAME:-"DXSpider Sysop"}
CLUSTER_QTH=${CLUSTER_QTH:-"DXSpider Node"}
CLUSTER_LOCATOR=$(echo "${CLUSTER_LOCATOR:-JO01aa}" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_EMAIL=$(echo "${CLUSTER_SYSOP_EMAIL:-sysop@localhost}" | sed 's/@/\\@/g')
CLUSTER_SYSOP_BBS_ADDRESS=$(echo "${CLUSTER_SYSOP_BBS_ADDRESS:-bbs@localhost}" | sed 's/@/\\@/g')

# Web Console credentials: fall back to DB creds, then to 'sysop' defaults.
# This preserves backward compatibility with older .env files.
WEB_USER=${WEB_USER:-${CLUSTER_DBUSER:-sysop}}
WEB_PASS=${WEB_PASS:-${CLUSTER_DBPASS:-sysoppassword}}

# =============================================================================
#  Step 6: Generate DXVars.pm from the upstream template
#
#  We sed the upstream DXVars.pm.issue template, substituting our env values
#  into the Perl variable assignments. Only generated if missing, unless
#  OVERWRITE_CONFIG=yes.
# =============================================================================
if [ ! -f ${SPIDER_INSTALL_DIR}/local/DXVars.pm ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
    # Substitute identity, location, and contact fields
    sed -e "s/\(\$mycall[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_CALLSIGN}\";/" \
        -e "s/\(\$myname[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_NAME}\";/" \
        -e "s/\(\$myalias[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_CALLSIGN}\";/" \
        -e "s/\(\$mylatitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LATITUDE:-0}\";/" \
        -e "s/\(\$mylongitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LONGITUDE:-0}\";/" \
        -e "s/\(\$myqth[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_QTH}\";/" \
        -e "s/\(\$mylocator[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LOCATOR}\";/" \
        -e "s/\(\$myemail[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_EMAIL}\";/" \
        -e "s/\(\$mybbsaddr[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_BBS_ADDRESS}\";/" \
        < ${SPIDER_INSTALL_DIR}/perl/DXVars.pm.issue > ${SPIDER_INSTALL_DIR}/local/DXVars.pm

    # Database backend: only enable when CLUSTER_DB_HOSTNAME is set.
    # In the template, $dsn/$dbuser/$dbpass are commented out (#$dsn=...).
    # We substitute the values and then uncomment those lines.
    # When no DB host is configured, DXSpider uses flat-file (DB_File/SQLite)
    # storage, which is the default and sufficient for most nodes.
    if [ -n "${CLUSTER_DB_HOSTNAME:-}" ]; then
        echo "Database backend enabled: ${CLUSTER_DB_HOSTNAME}"
        sed -e "s/\(\#\$dsn[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DSN}\";/" \
            -e "s/\(\#\$dbuser[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBUSER}\";/" \
            -e "s/\(\#\$dbpass[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBPASS}\";/" \
            -i ${SPIDER_INSTALL_DIR}/local/DXVars.pm
        # Uncomment the $dsn/$dbuser/$dbpass lines
        sed -i "/\$dsn/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
        sed -i "/\$dbuser/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
        sed -i "/\$dbpass/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    else
        echo "Database backend disabled (CLUSTER_DB_HOSTNAME not set) — using flat-file storage."
    fi
fi

# =============================================================================
#  Step 7: Clean stale lock files from previous (crashed) runs
#
#  DXSpider creates cluster.lck while running. If the container was killed
#  ungracefully, the lock file may persist and block startup.
# =============================================================================
rm -f ${SPIDER_INSTALL_DIR}/local/cluster.lck 2>/dev/null || true
rm -f ${SPIDER_INSTALL_DIR}/local_data/cluster.lck 2>/dev/null || true

# Switch to the Perl directory (DXSpider expects to run from here)
cd ${SPIDER_INSTALL_DIR}/perl

# =============================================================================
#  Step 8: Create / update the sysop user in the DXSpider user database
#
#  create_sysop.pl ensures the sysop callsign exists with admin privileges.
#  Runs as the sysop user so the user database file is owned correctly.
# =============================================================================
su-exec ${SPIDER_USERNAME} ./create_sysop.pl

# =============================================================================
#  Step 9: Start the DXSpider cluster daemon
#
#  cluster.pl is the main listener — it accepts telnet connections on
#  CLUSTER_PORT and handles all DX spot/announce/routing logic.
#  Runs in the background as the sysop user via su-exec.
# =============================================================================
echo "Starting DXSpider Cluster..."
su-exec ${SPIDER_USERNAME} ./cluster.pl &

# Wait briefly and verify the cluster process is alive.
# If it crashed (e.g., missing Perl module), exit with an error so
# Docker's restart policy can handle it.
sleep 5
if ! pgrep -f "cluster.pl" > /dev/null; then
    echo "FATAL: Cluster failed to start. Check your Perl dependencies." >&2
    exit 1
fi

# =============================================================================
#  Step 10: Start the ttyd Web Console
#
#  ttyd provides a browser-based terminal connected to DXSpider's console.pl.
#  -p   : listen port (CLUSTER_SYSOP_PORT, default 8080)
#  -u   : drop to SPIDER_UID for the spawned console.pl process
#  -t   : terminal font size
#  -W   : allow write access (needed for interactive console)
#  -c   : HTTP basic auth credentials (user:pass)
#
#  ttyd itself runs as root (to bind the port), but the child console.pl
#  process runs as the sysop user via the -u flag.
# =============================================================================
echo "Starting Web Console on port ${CLUSTER_SYSOP_PORT:-8080}..."
ttyd -p ${CLUSTER_SYSOP_PORT:-8080} -u ${SPIDER_UID} -t fontSize=16 -W \
    -c "${WEB_USER}:${WEB_PASS}" \
    perl ${SPIDER_INSTALL_DIR}/perl/console.pl &

# =============================================================================
#  Step 11: Wait for child processes
#
#  `wait` blocks until both background processes exit. When a signal arrives
#  (SIGTERM/SIGINT), the trap fires cleanup(), which kills both children
#  and exits cleanly.
# =============================================================================
wait
