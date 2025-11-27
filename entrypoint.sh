#!/bin/sh
# DXSpider Docker Entrypoint Script
#
# Features:
# - Generates configuration from environment variables
# - Handles graceful shutdown via signal trapping
# - Secure credential handling for ttyd
# - Validates startup before proceeding

set -e

# =============================================================================
# Environment Variable Validation
# =============================================================================
validate_env() {
    local missing=""

    # Required variables
    if [ -z "$CLUSTER_CALLSIGN" ]; then
        missing="${missing}CLUSTER_CALLSIGN "
    fi
    if [ -z "$CLUSTER_SYSOP_CALLSIGN" ]; then
        missing="${missing}CLUSTER_SYSOP_CALLSIGN "
    fi

    if [ -n "$missing" ]; then
        echo "[entrypoint] ERROR: Missing required environment variables: $missing"
        echo "[entrypoint] Please set these variables in your .env file"
        exit 1
    fi

    echo "[entrypoint] Environment validation passed"
}

validate_env

SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
CLUSTER_PORT=${CLUSTER_PORT:-7300}
CLUSTER_SYSOP_PORT=${CLUSTER_SYSOP_PORT:-8050}
CLUSTER_METRICS_PORT=${CLUSTER_METRICS_PORT:-9100}

# =============================================================================
# Signal Handling for Graceful Shutdown
# =============================================================================
CLUSTER_PID=""
TTYD_PID=""
METRICS_PID=""

cleanup() {
    echo "[entrypoint] Received shutdown signal, cleaning up..."

    # Stop metrics server first
    if [ -n "$METRICS_PID" ] && kill -0 "$METRICS_PID" 2>/dev/null; then
        echo "[entrypoint] Stopping metrics server (PID: $METRICS_PID)..."
        kill -TERM "$METRICS_PID" 2>/dev/null || true
    fi

    # Stop ttyd
    if [ -n "$TTYD_PID" ] && kill -0 "$TTYD_PID" 2>/dev/null; then
        echo "[entrypoint] Stopping ttyd (PID: $TTYD_PID)..."
        kill -TERM "$TTYD_PID" 2>/dev/null || true
    fi

    # Stop DXSpider cluster gracefully
    if [ -n "$CLUSTER_PID" ] && kill -0 "$CLUSTER_PID" 2>/dev/null; then
        echo "[entrypoint] Stopping DXSpider cluster (PID: $CLUSTER_PID)..."
        kill -TERM "$CLUSTER_PID" 2>/dev/null || true

        # Wait for graceful shutdown (max 10 seconds)
        for i in $(seq 1 10); do
            if ! kill -0 "$CLUSTER_PID" 2>/dev/null; then
                echo "[entrypoint] DXSpider stopped gracefully"
                break
            fi
            sleep 1
        done

        # Force kill if still running
        if kill -0 "$CLUSTER_PID" 2>/dev/null; then
            echo "[entrypoint] Force stopping DXSpider..."
            kill -9 "$CLUSTER_PID" 2>/dev/null || true
        fi
    fi

    # Clean up credential file
    rm -f /tmp/.ttyd_credentials

    echo "[entrypoint] Shutdown complete"
    exit 0
}

# Trap signals
trap cleanup SIGTERM SIGINT SIGHUP

# =============================================================================
# Generate Listeners.pm Configuration
# =============================================================================
if [ ! -f "${SPIDER_INSTALL_DIR}/local/Listeners.pm" ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
    echo "[entrypoint] Generating Listeners.pm..."
    cat << EOF > ${SPIDER_INSTALL_DIR}/local/Listeners.pm
package main;

use vars qw(@listen);

@listen = (
    ["0.0.0.0", ${CLUSTER_PORT}],
);

1;
EOF
fi

# =============================================================================
# Normalize Callsigns and Locator to Uppercase
# =============================================================================
CLUSTER_CALLSIGN=$(echo "${CLUSTER_CALLSIGN}" | tr '[:lower:]' '[:upper:]')
CLUSTER_SYSOP_CALLSIGN=$(echo "${CLUSTER_SYSOP_CALLSIGN}" | tr '[:lower:]' '[:upper:]')
CLUSTER_LOCATOR=$(echo "${CLUSTER_LOCATOR}" | tr '[:lower:]' '[:upper:]')

# Escape email addresses for Perl
CLUSTER_SYSOP_EMAIL_ESCAPED=$(echo "${CLUSTER_SYSOP_EMAIL}" | sed 's/@/\\@/g')
CLUSTER_SYSOP_BBS_ADDRESS_ESCAPED=$(echo "${CLUSTER_SYSOP_BBS_ADDRESS}" | sed 's/@/\\@/g')

# =============================================================================
# Generate DXVars.pm Configuration
# =============================================================================
if [ ! -f "${SPIDER_INSTALL_DIR}/local/DXVars.pm" ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
    echo "[entrypoint] Generating DXVars.pm..."
    sed -e "s/\(\$mycall[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_CALLSIGN}\";/" \
        -e "s/\(\$myname[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_NAME}\";/" \
        -e "s/\(\$myalias[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_CALLSIGN}\";/" \
        -e "s/\(\$mylatitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LATITUDE:-0}\";/" \
        -e "s/\(\$mylongitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LONGITUDE:-0}\";/" \
        -e "s/\(\$myqth[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_QTH}\";/" \
        -e "s/\(\$mylocator[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LOCATOR}\";/" \
        -e "s/\(\$myemail[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_EMAIL_ESCAPED}\";/" \
        -e "s/\(\$mybbsaddr[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_BBS_ADDRESS_ESCAPED}\";/" \
        -e "s/\(\#\$dsn[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DSN}\";/" \
        -e "s/\(\#\$dbuser[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBUSER}\";/" \
        -e "s/\(\#\$dbpass[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_DBPASS}\";/" \
        < ${SPIDER_INSTALL_DIR}/perl/DXVars.pm.issue > ${SPIDER_INSTALL_DIR}/local/DXVars.pm

    # Remove leading # from database config lines
    sed -i "/\$dsn/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    sed -i "/\$dbuser/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    sed -i "/\$dbpass/s/^#*//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
    sed -i "/\$Internet::contest_host/s/'//g" ${SPIDER_INSTALL_DIR}/local/DXVars.pm
fi

# =============================================================================
# Clean Stale Lock Files
# =============================================================================
echo "[entrypoint] Cleaning stale lock files..."
rm -f ${SPIDER_INSTALL_DIR}/local/cluster.lck
rm -f ${SPIDER_INSTALL_DIR}/local_data/cluster.lck

# =============================================================================
# Initialize Notification System (Optional)
# =============================================================================
if [ -f "${SPIDER_INSTALL_DIR}/notifications/config/notifications.yml" ]; then
    echo "[entrypoint] Notification system configuration found"
    # Copy notification libraries if not already in place
    if [ -d "${SPIDER_INSTALL_DIR}/notifications/lib" ]; then
        cp -n ${SPIDER_INSTALL_DIR}/notifications/lib/*.pm ${SPIDER_INSTALL_DIR}/local/ 2>/dev/null || true
        cp -rn ${SPIDER_INSTALL_DIR}/notifications/lib/Notify ${SPIDER_INSTALL_DIR}/local/ 2>/dev/null || true
        echo "[entrypoint] Notification modules loaded"
    fi
else
    echo "[entrypoint] Notification system not configured (optional)"
fi

# =============================================================================
# Start DXSpider Cluster
# =============================================================================
echo "[entrypoint] Starting DXSpider cluster..."
cd ${SPIDER_INSTALL_DIR}/perl

# Create sysop user if needed
./create_sysop.pl

# Start cluster in background
./cluster.pl &
CLUSTER_PID=$!

# Wait for cluster to start (with timeout)
echo "[entrypoint] Waiting for cluster to start..."
STARTUP_TIMEOUT=30
for i in $(seq 1 $STARTUP_TIMEOUT); do
    if nc -z localhost ${CLUSTER_PORT} 2>/dev/null; then
        echo "[entrypoint] DXSpider cluster started successfully (PID: $CLUSTER_PID)"
        break
    fi

    # Check if process is still running
    if ! kill -0 "$CLUSTER_PID" 2>/dev/null; then
        echo "[entrypoint] ERROR: DXSpider cluster failed to start!"
        exit 1
    fi

    sleep 1
done

# Verify cluster is running
if ! nc -z localhost ${CLUSTER_PORT} 2>/dev/null; then
    echo "[entrypoint] ERROR: DXSpider cluster did not start within ${STARTUP_TIMEOUT} seconds"
    exit 1
fi

# =============================================================================
# Start ttyd Web Console
# =============================================================================
echo "[entrypoint] Starting ttyd web console on port ${CLUSTER_SYSOP_PORT}..."

# Security: Write credentials to file instead of passing on command line
# This prevents credentials from being visible in 'ps aux' output
TTYD_CRED_FILE="/tmp/.ttyd_credentials"
echo "${CLUSTER_DBUSER:-sysop}:${CLUSTER_DBPASS:-password}" > "${TTYD_CRED_FILE}"
chmod 600 "${TTYD_CRED_FILE}"

# Start ttyd in background
ttyd -p ${CLUSTER_SYSOP_PORT} -u 1000 -t fontSize=16 -c "@${TTYD_CRED_FILE}" perl /spider/perl/console.pl &
TTYD_PID=$!

echo "[entrypoint] ttyd started (PID: $TTYD_PID)"

# =============================================================================
# Start Prometheus Metrics Server (Optional)
# =============================================================================
if [ -f "${SPIDER_INSTALL_DIR}/metrics/metrics_server.pl" ]; then
    echo "[entrypoint] Starting Prometheus metrics server on port ${CLUSTER_METRICS_PORT}..."
    cd ${SPIDER_INSTALL_DIR}/metrics
    perl metrics_server.pl daemon -l http://*:${CLUSTER_METRICS_PORT} &
    METRICS_PID=$!
    echo "[entrypoint] Metrics server started (PID: $METRICS_PID)"
    cd ${SPIDER_INSTALL_DIR}/perl
else
    echo "[entrypoint] Metrics server script not found, skipping metrics..."
fi

echo "[entrypoint] DXSpider is ready!"
echo "[entrypoint]   - Telnet: port ${CLUSTER_PORT}"
echo "[entrypoint]   - Web Console: port ${CLUSTER_SYSOP_PORT}"
[ -n "$METRICS_PID" ] && echo "[entrypoint]   - Metrics: port ${CLUSTER_METRICS_PORT}"

# =============================================================================
# Wait for Processes (and handle signals)
# =============================================================================
# Wait for any process to exit
if [ -n "$METRICS_PID" ]; then
    wait -n $CLUSTER_PID $TTYD_PID $METRICS_PID 2>/dev/null || true
else
    wait -n $CLUSTER_PID $TTYD_PID 2>/dev/null || true
fi

# If we get here, one of the processes died unexpectedly
echo "[entrypoint] A process exited unexpectedly, shutting down..."
cleanup
