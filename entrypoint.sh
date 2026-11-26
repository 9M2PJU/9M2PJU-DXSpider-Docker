#!/bin/bash
# =============================================================================
#  9M2PJU DXSpider Docker - Container Entrypoint
#
#  Responsibilities (in order):
#    1. Fix ownership of bind-mounted volumes (runs as root)
#    2. Symlink internal data dirs & seed default configs if missing
#    3. Generate Listeners.pm (telnet listen address/port)
#    4. Generate DXVars.pm safely via Perl (cluster identity, location, optional DB)
#    5. Clean stale lock files from previous runs
#    6. Initialize the sysop user DB ONLY on first boot (never overwrite existing DB)
#    7. Start cluster.pl as the sysop user (via su-exec)
#    8. Optionally start the ttyd web console (drops to sysop UID for console.pl)
#    9. Supervise children (wait -n) and forward SIGTERM/SIGINT for clean flush
# =============================================================================
set -euo pipefail

# --- Resolve runtime configuration with safe defaults ---
SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
SPIDER_UID=${SPIDER_UID:-1000}
SPIDER_GROUP=${SPIDER_USERNAME}
OVERWRITE_CONFIG=${OVERWRITE_CONFIG:-no}
ENABLE_WEB_CONSOLE=${ENABLE_WEB_CONSOLE:-yes}

CLUSTER_PID=""
TTYD_PID=""
SHUTTING_DOWN=0

# =============================================================================
#  Signal handler: Graceful shutdown on SIGTERM / SIGINT
#
#  Docker sends SIGTERM on `docker stop`. We forward SIGTERM directly to
#  cluster.pl and wait for it to finish flushing SQLite (dxusers.db) before
#  exiting so user records are never corrupted or truncated.
# =============================================================================
cleanup() {
    SHUTTING_DOWN=1
    echo "Stopping DXSpider Cluster gracefully..."
    if [ -n "${TTYD_PID}" ] && kill -0 "${TTYD_PID}" 2>/dev/null; then
        kill -TERM "${TTYD_PID}" 2>/dev/null || true
    fi
    # Signal cluster.pl as SPIDER_USERNAME so SIGTERM works even with CAP_KILL dropped
    if [ -n "${CLUSTER_PID}" ] && su-exec "${SPIDER_USERNAME}" kill -0 "${CLUSTER_PID}" 2>/dev/null; then
        su-exec "${SPIDER_USERNAME}" kill -TERM "${CLUSTER_PID}" 2>/dev/null || true
        wait "${CLUSTER_PID}" 2>/dev/null || true
    fi
    if [ -n "${TTYD_PID}" ]; then
        wait "${TTYD_PID}" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup SIGTERM SIGINT

# =============================================================================
#  Normalize cluster identity values early (used by MOTD templates and DXVars.pm)
# =============================================================================
CLUSTER_CALLSIGN=$(printf '%s' "${CLUSTER_CALLSIGN:-N0CALL-2}" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_CALLSIGN=$(printf '%s' "${CLUSTER_SYSOP_CALLSIGN:-9M2PJU}" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_NAME=${CLUSTER_SYSOP_NAME:-"DXSpider Sysop"}
CLUSTER_QTH=${CLUSTER_QTH:-"DXSpider Node"}
CLUSTER_LOCATOR=$(printf '%s' "${CLUSTER_LOCATOR:-JO01aa}" | tr 'a-z' 'A-Z')
CLUSTER_LATITUDE=${CLUSTER_LATITUDE:-0}
CLUSTER_LONGITUDE=${CLUSTER_LONGITUDE:-0}
CLUSTER_SYSOP_EMAIL=${CLUSTER_SYSOP_EMAIL:-"9m2pju@hamradio.my"}
CLUSTER_SYSOP_BBS_ADDRESS=${CLUSTER_SYSOP_BBS_ADDRESS:-"bbs@localhost"}

# Web Console credentials: fall back to DB creds, then to 'sysop' defaults.
# Preserves backward compatibility with older .env files.
WEB_USER=${WEB_USER:-${CLUSTER_DBUSER:-sysop}}
WEB_PASS=${WEB_PASS:-${CLUSTER_DBPASS:-sysoppassword}}

# Export normalized values so Perl substitution blocks read them cleanly via %ENV
export CLUSTER_CALLSIGN CLUSTER_SYSOP_CALLSIGN CLUSTER_SYSOP_NAME CLUSTER_QTH \
       CLUSTER_LOCATOR CLUSTER_LATITUDE CLUSTER_LONGITUDE \
       CLUSTER_SYSOP_EMAIL CLUSTER_SYSOP_BBS_ADDRESS \
       CLUSTER_DB_HOSTNAME CLUSTER_DSN CLUSTER_DBUSER CLUSTER_DBPASS

# =============================================================================
#  Step 1: Fix permissions on bind-mounted volumes
# =============================================================================
mkdir -p "${SPIDER_INSTALL_DIR}/local" \
         "${SPIDER_INSTALL_DIR}/local_data" \
         "${SPIDER_INSTALL_DIR}/local_cmd"

chown -R "${SPIDER_USERNAME}:${SPIDER_GROUP}" \
    "${SPIDER_INSTALL_DIR}/local" \
    "${SPIDER_INSTALL_DIR}/local_data" \
    "${SPIDER_INSTALL_DIR}/local_cmd" 2>/dev/null || true

# =============================================================================
#  Step 2: Symlink internal data dirs & seed default config files if missing
# =============================================================================
for dir in log spots debug; do
    mkdir -p "${SPIDER_INSTALL_DIR}/local_data/${dir}"
    if [ -d "${SPIDER_INSTALL_DIR}/data/${dir}" ] && [ ! -L "${SPIDER_INSTALL_DIR}/data/${dir}" ]; then
        cp -an "${SPIDER_INSTALL_DIR}/data/${dir}/." "${SPIDER_INSTALL_DIR}/local_data/${dir}/" 2>/dev/null || true
        rm -rf "${SPIDER_INSTALL_DIR}/data/${dir}"
    fi
    ln -sf "${SPIDER_INSTALL_DIR}/local_data/${dir}" "${SPIDER_INSTALL_DIR}/data/${dir}"
    chown -R "${SPIDER_USERNAME}:${SPIDER_GROUP}" "${SPIDER_INSTALL_DIR}/local_data/${dir}" 2>/dev/null || true
done

# Seed local_cmd/crontab on first run if absent
if [ ! -f "${SPIDER_INSTALL_DIR}/local_cmd/crontab" ] && [ -f "${SPIDER_INSTALL_DIR}/defaults/crontab.example" ]; then
    echo "Seeding default local_cmd/crontab..."
    cp "${SPIDER_INSTALL_DIR}/defaults/crontab.example" "${SPIDER_INSTALL_DIR}/local_cmd/crontab"
    chown "${SPIDER_USERNAME}:${SPIDER_GROUP}" "${SPIDER_INSTALL_DIR}/local_cmd/crontab" 2>/dev/null || true
fi

# Seed local_cmd/startup on first run if absent, and link /spider/scripts/startup to it
# (unless /spider/scripts/startup was directly bind-mounted by the user)
if ! mountpoint -q "${SPIDER_INSTALL_DIR}/scripts/startup" 2>/dev/null; then
    if [ ! -f "${SPIDER_INSTALL_DIR}/local_cmd/startup" ] && [ -f "${SPIDER_INSTALL_DIR}/defaults/startup.example" ]; then
        echo "Seeding default local_cmd/startup..."
        cp "${SPIDER_INSTALL_DIR}/defaults/startup.example" "${SPIDER_INSTALL_DIR}/local_cmd/startup"
        chown "${SPIDER_USERNAME}:${SPIDER_GROUP}" "${SPIDER_INSTALL_DIR}/local_cmd/startup" 2>/dev/null || true
    fi
    if [ -f "${SPIDER_INSTALL_DIR}/local_cmd/startup" ]; then
        ln -sf "${SPIDER_INSTALL_DIR}/local_cmd/startup" "${SPIDER_INSTALL_DIR}/scripts/startup"
    fi
fi

# Render default MOTD files into local_data/ on first run if absent
render_template() {
    local src="$1"
    local dst="$2"
    perl -pe '
        s/\{\{CLUSTER_CALLSIGN\}\}/$ENV{CLUSTER_CALLSIGN}/ge;
        s/\{\{CLUSTER_QTH\}\}/$ENV{CLUSTER_QTH}/ge;
        s/\{\{CLUSTER_SYSOP_EMAIL\}\}/$ENV{CLUSTER_SYSOP_EMAIL}/ge;
    ' "$src" > "$dst"
    chown "${SPIDER_USERNAME}:${SPIDER_GROUP}" "$dst" 2>/dev/null || true
}

if [ ! -f "${SPIDER_INSTALL_DIR}/local_data/motd" ] && [ -f "${SPIDER_INSTALL_DIR}/defaults/motd.template" ]; then
    echo "Seeding default local_data/motd for ${CLUSTER_CALLSIGN}..."
    render_template "${SPIDER_INSTALL_DIR}/defaults/motd.template" "${SPIDER_INSTALL_DIR}/local_data/motd"
fi

if [ ! -f "${SPIDER_INSTALL_DIR}/local_data/motd_nor" ] && [ -f "${SPIDER_INSTALL_DIR}/defaults/motd_nor.template" ]; then
    echo "Seeding default local_data/motd_nor for ${CLUSTER_CALLSIGN}..."
    render_template "${SPIDER_INSTALL_DIR}/defaults/motd_nor.template" "${SPIDER_INSTALL_DIR}/local_data/motd_nor"
fi

# =============================================================================
#  Step 3: Generate Listeners.pm (telnet listen configuration)
# =============================================================================
if [ ! -f "${SPIDER_INSTALL_DIR}/local/Listeners.pm" ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
cat << EOF > "${SPIDER_INSTALL_DIR}/local/Listeners.pm"
package main;
use vars qw(@listen);
@listen = (
    ["0.0.0.0", ${CLUSTER_PORT:-7300}],
);
1;
EOF
fi

# =============================================================================
#  Step 4: Generate DXVars.pm safely from upstream template via Perl
#
#  Using Perl with %ENV avoids sed delimiter/escaping bugs when values
#  contain '/', '&', '$', '@', '"', or '\'.
# =============================================================================
if [ ! -f "${SPIDER_INSTALL_DIR}/local/DXVars.pm" ] || [ "${OVERWRITE_CONFIG}" = "yes" ]; then
    perl -e '
        use strict;
        use warnings;

        sub q_perl {
            my ($v) = @_;
            $v = "" unless defined $v;
            $v =~ s/([\\"\$\@])/\\$1/g;
            return qq{"$v"};
        }

        my %vars = (
            mycall      => $ENV{CLUSTER_CALLSIGN},
            myname      => $ENV{CLUSTER_SYSOP_NAME},
            myalias     => $ENV{CLUSTER_SYSOP_CALLSIGN},
            mylatitude  => $ENV{CLUSTER_LATITUDE},
            mylongitude => $ENV{CLUSTER_LONGITUDE},
            myqth       => $ENV{CLUSTER_QTH},
            mylocator   => $ENV{CLUSTER_LOCATOR},
            myemail     => $ENV{CLUSTER_SYSOP_EMAIL},
            mybbsaddr   => $ENV{CLUSTER_SYSOP_BBS_ADDRESS},
        );

        my $db_enabled = defined($ENV{CLUSTER_DB_HOSTNAME}) && length($ENV{CLUSTER_DB_HOSTNAME}) > 0;
        my %db_vars = (
            dsn    => $ENV{CLUSTER_DSN},
            dbuser => $ENV{CLUSTER_DBUSER},
            dbpass => $ENV{CLUSTER_DBPASS},
        );

        while (my $line = <STDIN>) {
            for my $k (keys %vars) {
                if ($line =~ /^(\s*(?:our\s+)?\$\Q$k\E\s*=\s*).*$/) {
                    $line = $1 . q_perl($vars{$k}) . ";\n";
                    last;
                }
            }
            if ($db_enabled) {
                for my $k (keys %db_vars) {
                    if ($line =~ /^#?(\s*(?:our\s+)?\$\Q$k\E\s*=\s*).*$/) {
                        $line = $1 . q_perl($db_vars{$k}) . ";\n";
                        last;
                    }
                }
            }
            print $line;
        }
    ' < "${SPIDER_INSTALL_DIR}/perl/DXVars.pm.issue" > "${SPIDER_INSTALL_DIR}/local/DXVars.pm"

    if [ -n "${CLUSTER_DB_HOSTNAME:-}" ]; then
        echo "Database backend enabled: ${CLUSTER_DB_HOSTNAME}"
    else
        echo "Database backend disabled (CLUSTER_DB_HOSTNAME not set) - using flat-file storage."
    fi
fi

# Ensure SQLite user DB DSN is present in DXVars.pm (required by Mojo >= SQLite migration)
if ! grep -qE '^\s*our\s+\$userdsn\s*=' "${SPIDER_INSTALL_DIR}/local/DXVars.pm"; then
    perl -0pi -e 's/\n1;\s*\z/\nour \$userdsn = "dbi:SQLite:dbname=\$root\/local_data\/dxusers.db";\n\n1;\n/ or die "DXVars.pm: final 1; not found\n"' "${SPIDER_INSTALL_DIR}/local/DXVars.pm"
fi
chown "${SPIDER_USERNAME}:${SPIDER_GROUP}" "${SPIDER_INSTALL_DIR}/local/DXVars.pm" "${SPIDER_INSTALL_DIR}/local/Listeners.pm" 2>/dev/null || true

# =============================================================================
#  Step 5: Clean stale lock files from previous (crashed) runs
# =============================================================================
rm -f "${SPIDER_INSTALL_DIR}/local/cluster.lck" 2>/dev/null || true
rm -f "${SPIDER_INSTALL_DIR}/local_data/cluster.lck" 2>/dev/null || true

# Switch to the Perl directory (DXSpider expects to run from here)
cd "${SPIDER_INSTALL_DIR}/perl"

# =============================================================================
#  Step 6: Initialize the sysop user database ONLY on first boot
#
#  Never invoke create_sysop.pl on updates/restarts when an existing user DB
#  is present: upstream create_sysop.pl deletes and recreates $mycall/$myalias
#  records when legacy users.v2/v3 files are absent, wiping passwords and
#  persistent attributes.
# =============================================================================
if [ ! -f "${SPIDER_INSTALL_DIR}/local_data/dxusers.db" ] && \
   [ ! -f "${SPIDER_INSTALL_DIR}/local_data/users.v3j" ] && \
   [ ! -f "${SPIDER_INSTALL_DIR}/local_data/users.v3" ] && \
   [ ! -f "${SPIDER_INSTALL_DIR}/local_data/users.v2" ]; then
    echo "Initializing new DXSpider user database..."
    su-exec "${SPIDER_USERNAME}" ./create_sysop.pl
else
    echo "Existing DXSpider user database found; skipping create_sysop.pl."
fi

# =============================================================================
#  Step 7: Start the DXSpider cluster daemon
# =============================================================================
echo "Starting DXSpider Cluster..."
su-exec "${SPIDER_USERNAME}" ./cluster.pl &
CLUSTER_PID=$!

# Verify the cluster process stayed alive after initial boot
# Check as SPIDER_USERNAME because CAP_KILL is dropped under cap_drop: ALL
sleep 5
if ! su-exec "${SPIDER_USERNAME}" kill -0 "${CLUSTER_PID}" 2>/dev/null; then
    echo "FATAL: Cluster failed to start. Check your Perl dependencies and DXVars.pm." >&2
    exit 1
fi

# =============================================================================
#  Step 8: Optionally start the ttyd Web Console
# =============================================================================
case "$(printf '%s' "${ENABLE_WEB_CONSOLE}" | tr 'A-Z' 'a-z')" in
    yes|true|1|on)
        echo "Starting Web Console on port ${CLUSTER_SYSOP_PORT:-8080}..."
        ttyd -p "${CLUSTER_SYSOP_PORT:-8080}" -u "${SPIDER_UID}" -t fontSize=16 -W \
            -c "${WEB_USER}:${WEB_PASS}" \
            perl "${SPIDER_INSTALL_DIR}/perl/console.pl" &
        TTYD_PID=$!
        ;;
    *)
        echo "Web Console disabled (ENABLE_WEB_CONSOLE=${ENABLE_WEB_CONSOLE})."
        ;;
esac

# =============================================================================
#  Step 9: Supervise child processes
#
#  If cluster.pl (or ttyd) exits unexpectedly, tear down cleanly and return
#  non-zero so Docker's restart policy automatically recovers the container.
# =============================================================================
set +e
if [ -n "${TTYD_PID}" ]; then
    wait -n "${CLUSTER_PID}" "${TTYD_PID}"
    EXIT_CODE=$?
else
    wait "${CLUSTER_PID}"
    EXIT_CODE=$?
fi
set -e

if [ "${SHUTTING_DOWN}" -eq 1 ]; then
    exit 0
fi

echo "A managed process exited unexpectedly (code ${EXIT_CODE}); shutting down container..." >&2
if [ -n "${TTYD_PID}" ] && kill -0 "${TTYD_PID}" 2>/dev/null; then
    kill -TERM "${TTYD_PID}" 2>/dev/null || true
    wait "${TTYD_PID}" 2>/dev/null || true
fi
if [ -n "${CLUSTER_PID}" ] && su-exec "${SPIDER_USERNAME}" kill -0 "${CLUSTER_PID}" 2>/dev/null; then
    su-exec "${SPIDER_USERNAME}" kill -TERM "${CLUSTER_PID}" 2>/dev/null || true
    wait "${CLUSTER_PID}" 2>/dev/null || true
fi
exit "${EXIT_CODE:-1}"
