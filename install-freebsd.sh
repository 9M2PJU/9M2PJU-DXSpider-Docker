#!/usr/local/bin/bash
# =============================================================================
#  9M2PJU DXSpider Docker — FreeBSD native installer
#
#  Docker does NOT run on FreeBSD (it requires Linux cgroups/namespaces).
#  This script installs DXSpider natively on FreeBSD using:
#    - FreeBSD pkg for Perl + p5-* CPAN modules
#    - A dedicated 'sysop' user
#    - An rc.d service for startup
#    - ttyd for the web console (optional)
#
#  No Docker, no container — just a clean FreeBSD install.
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install-freebsd.sh | bash
#
#  Or from a clone:
#    bash install-freebsd.sh
# =============================================================================
set -euo pipefail

# --- Config ---
SPIDER_DIR="${SPIDER_DIR:-/usr/local/spider}"
SPIDER_USER="${SPIDER_USER:-sysop}"
SPIDER_UID="${SPIDER_UID:-1000}"
SPIDER_GID="${SPIDER_GID:-1000}"
SPIDER_BRANCH="${SPIDER_BRANCH:-mojo}"
DXSPIDER_REPO="https://github.com/EA3CV/dxspider.git"
SERVICE_NAME="dxspider"
TTYD_SERVICE_NAME="dxspider-web"

# --- Helpers ---
c_bold() { printf '\033[1m%s\033[0m' "$1"; }
c_green() { printf '\033[32m%s\033[0m' "$1"; }
c_red()   { printf '\033[31m%s\033[0m' "$1"; }
c_yellow(){ printf '\033[33m%s\033[0m' "$1"; }
c_blue()  { printf '\033[34m%s\033[0m' "$1"; }

info()  { printf "%s %s\n" "$(c_blue '[INFO]')" "$*"; }
ok()    { printf "%s %s\n" "$(c_green '[OK]')" "$*"; }
warn()  { printf "%s %s\n" "$(c_yellow '[WARN]')" "$*"; }
die()   { printf "%s %s\n" "$(c_red '[FATAL]')" "$*"; exit 1; }

prompt() {
    local question="$1" default="${2:-}" var
    if [ -n "$default" ]; then
        printf "%s %s [%s]: " "$(c_bold '?')" "$question" "$default"
    else
        printf "%s %s: " "$(c_bold '?')" "$question"
    fi
    read -r var
    echo "${var:-$default}"
}

# =============================================================================
#  Preflight checks
# =============================================================================
[ "$(uname -s)" = "FreeBSD" ] || die "This script is for FreeBSD only. Use install.sh on Linux."

if [ "$(id -u)" -ne 0 ]; then
    warn "Root privileges required. Re-running with sudo..."
    exec sudo -E bash "$0" "$@"
fi

echo ""
echo "$(c_bold '========================================')"
echo "$(c_bold '  9M2PJU DXSpider Docker — FreeBSD')"
echo "$(c_bold '  Native Install (no Docker)')"
echo "$(c_bold '========================================')"
echo ""

info "Detected: FreeBSD $(freebsd-version)"

# =============================================================================
#  Step 1: Install dependencies via pkg
# =============================================================================
info "Installing Perl + CPAN modules + utilities via pkg..."

# Bootstrap pkg if needed
if ! command -v pkg >/dev/null 2>&1; then
    info "Bootstrapping pkg..."
    ASSUME_ALWAYS_YES=yes /usr/sbin/pkg bootstrap
fi

# DXSpider Perl dependencies — all available as FreeBSD p5-* packages
# This is the FreeBSD equivalent of the Dockerfile's apk add + cpanm steps.
pkg install -y \
    bash \
    git \
    wget \
    nano \
    perl5 \
    p5-DB_File \
    p5-DBI \
    p5-DBD-SQLite \
    p5-DBD-mysql \
    p5-Digest-SHA1 \
    p5-IO-Socket-SSL \
    p5-Net-Telnet \
    p5-TimeDate \
    p5-YAML-LibYAML \
    p5-Curses \
    p5-Mojolicious \
    p5-Math-Round \
    p5-JSON \
    p5-JSON-XS \
    p5-Net-CIDR-Lite \
    p5-Date-Calc \
    p5-Date-Manip \
    p5-List-MoreUtils \
    p5-EV \
    p5-Authen-SASL \
    p5-Net-MQTT-Simple \
    p5-File-Copy-Recursive \
    p5-Data-Structure-Util \
    ttyd \
    netcat

ok "Dependencies installed."

# =============================================================================
#  Step 2: Create the sysop user
# =============================================================================
if ! pw user show "$SPIDER_USER" >/dev/null 2>&1; then
    info "Creating user '$SPIDER_USER' (UID $SPIDER_UID)..."
    pw groupadd -n "$SPIDER_USER" -g "$SPIDER_GID" 2>/dev/null || true
    pw useradd -n "$SPIDER_USER" -u "$SPIDER_UID" -g "$SPIDER_GID" \
        -d "$SPIDER_DIR" -s /usr/local/bin/bash -c "DXSpider Sysop"
else
    ok "User '$SPIDER_USER' already exists."
fi

# =============================================================================
#  Step 3: Clone or update DXSpider
# =============================================================================
if [ -d "$SPIDER_DIR/.git" ]; then
    info "Existing DXSpider found at $SPIDER_DIR — updating..."
    su -m "$SPIDER_USER" -c "git -C $SPIDER_DIR fetch --quiet origin $SPIDER_BRANCH"
    su -m "$SPIDER_USER" -c "git -C $SPIDER_DIR reset --hard origin/$SPIDER_BRANCH --quiet"
    ok "Updated to latest."
else
    info "Cloning DXSpider ($SPIDER_BRANCH branch) to $SPIDER_DIR ..."
    if [ -d "$SPIDER_DIR" ] && [ ! -d "$SPIDER_DIR/.git" ]; then
        warn "$SPIDER_DIR exists but is not a git repo. Backing up..."
        mv "$SPIDER_DIR" "${SPIDER_DIR}.bak.$(date +%s)"
    fi
    mkdir -p "$SPIDER_DIR"
    chown "$SPIDER_USER:$SPIDER_USER" "$SPIDER_DIR"
    su -m "$SPIDER_USER" -c "git clone --branch $SPIDER_BRANCH $DXSPIDER_REPO $SPIDER_DIR"
    ok "Cloned."
fi

# Create runtime directories
for d in local local_cmd local_data data/log data/spots data/debug; do
    mkdir -p "$SPIDER_DIR/$d"
done
chown -R "$SPIDER_USER:$SPIDER_USER" "$SPIDER_DIR"

# =============================================================================
#  Step 4: Interactive configuration
# =============================================================================
echo ""
echo "$(c_bold 'Configuration')"
echo "Please answer the following. Press Enter to accept the [default]."
echo ""

CLUSTER_CALLSIGN=$(prompt "Node callsign (SSID allowed, e.g. -2)" "9M2PJU-2")
CLUSTER_SYSOP_CALLSIGN=$(prompt "Your sysop callsign" "9M2PJU")
CLUSTER_SYSOP_NAME=$(prompt "Your name" "Sysop")
CLUSTER_LOCATOR=$(prompt "Maidenhead grid locator" "OJ03UD")
CLUSTER_QTH=$(prompt "QTH description (city, country)" "Kuala Lumpur, Malaysia")
CLUSTER_LATITUDE=$(prompt "Latitude (decimal degrees, +N/-S)" "+03.08")
CLUSTER_LONGITUDE=$(prompt "Longitude (decimal degrees, +E/-W)" "+101.41")
CLUSTER_SYSOP_EMAIL=$(prompt "Contact email (shown to users)" "9m2pju@hamradio.my")
CLUSTER_PORT=$(prompt "Telnet port" "7300")
CLUSTER_SYSOP_PORT=$(prompt "Web console port (ttyd)" "8080")
WEB_USER=$(prompt "Web console username" "sysop")
WEB_PASS=$(prompt "Web console password (CHANGE THIS!)" "$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)")

# Uppercase callsigns/locator
CLUSTER_CALLSIGN=$(echo "$CLUSTER_CALLSIGN" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_CALLSIGN=$(echo "$CLUSTER_SYSOP_CALLSIGN" | tr 'a-z' 'A-Z')
CLUSTER_LOCATOR=$(echo "$CLUSTER_LOCATOR" | tr 'a-z' 'A-Z')

# Escape @ for Perl string literals
CLUSTER_SYSOP_EMAIL_ESC=$(echo "$CLUSTER_SYSOP_EMAIL" | sed 's/@/\\@/g')

# =============================================================================
#  Step 5: Generate DXVars.pm and Listeners.pm
# =============================================================================
info "Generating DXVars.pm and Listeners.pm..."

# Generate Listeners.pm
cat > "$SPIDER_DIR/local/Listeners.pm" <<EOF
package main;
use vars qw(@listen);
@listen = (
    ["0.0.0.0", $CLUSTER_PORT],
);
1;
EOF

# Generate DXVars.pm from the upstream template
# (same sed logic as the Docker entrypoint.sh)
sed -e "s/\(\$mycall[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_CALLSIGN}\";/" \
    -e "s/\(\$myname[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_NAME}\";/" \
    -e "s/\(\$myalias[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_CALLSIGN}\";/" \
    -e "s/\(\$mylatitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LATITUDE}\";/" \
    -e "s/\(\$mylongitude[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LONGITUDE}\";/" \
    -e "s/\(\$myqth[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_QTH}\";/" \
    -e "s/\(\$mylocator[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_LOCATOR}\";/" \
    -e "s/\(\$myemail[[:space:]]*=[[:space:]]*\).*$/\1\"${CLUSTER_SYSOP_EMAIL_ESC}\";/" \
    < "$SPIDER_DIR/perl/DXVars.pm.issue" > "$SPIDER_DIR/local/DXVars.pm"

# Set permissions
chown "$SPIDER_USER:$SPIDER_USER" "$SPIDER_DIR/local/Listeners.pm" "$SPIDER_DIR/local/DXVars.pm"
ok "Config files generated."

# =============================================================================
#  Step 6: Create the sysop user in DXSpider's user database
# =============================================================================
info "Creating DXSpider sysop user..."
cd "$SPIDER_DIR/perl"
su -m "$SPIDER_USER" -c "perl create_sysop.pl"
ok "Sysop user created."

# =============================================================================
#  Step 7: Create rc.d startup scripts
# =============================================================================
info "Installing rc.d service scripts..."

# --- DXSpider cluster service ---
cat > "/usr/local/etc/rc.d/$SERVICE_NAME" <<'RCD'
#!/bin/sh
#
# DXSpider cluster — rc.d startup script for FreeBSD
#
# Add to /etc/rc.conf:
#   dxspider_enable="YES"
#

. /etc/rc.subr

name=dxspider
rcvar=dxspider_enable

load_rc_config "$name"

: ${dxspider_enable:="NO"}
: ${dxspider_user:="sysop"}
: ${dxspider_dir:="/usr/local/spider"}

pidfile="${dxspider_dir}/local_data/cluster.pid"
procname="perl"
command="/usr/sbin/daemon"
command_args="-f -p ${pidfile} -u ${dxspider_user} /usr/local/bin/perl ${dxspider_dir}/perl/cluster.pl"

start_precmd="cd ${dxspider_dir}/perl"
stop_postcmd="[ -f ${pidfile} ] && rm -f ${pidfile}"

run_rc_command "$1"
RCD
chmod +x "/usr/local/etc/rc.d/$SERVICE_NAME"

# --- ttyd web console service ---
cat > "/usr/local/etc/rc.d/$TTYD_SERVICE_NAME" <<RCD
#!/bin/sh
#
# DXSpider web console (ttyd) — rc.d startup script for FreeBSD
#
# Add to /etc/rc.conf:
#   dxspider_web_enable="YES"
#   dxspider_web_user="sysop"
#   dxspider_web_pass="changeme"
#

. /etc/rc.subr

name=dxspider_web
rcvar=dxspider_web_enable

load_rc_config "\$name"

: \${dxspider_web_enable:="NO"}
: \${dxspider_web_user:="sysop"}
: \${dxspider_web_pass:="changeme"}
: \${dxspider_web_port:="8080"}
: \${dxspider_web_uid:="1000"}
: \${dxspider_web_dir:="/usr/local/spider"}

procname="ttyd"
command="/usr/local/bin/ttyd"
command_args="-p \${dxspider_web_port} -u \${dxspider_web_uid} -t fontSize=16 -W -c \${dxspider_web_user}:\${dxspider_web_pass} perl \${dxspider_web_dir}/perl/console.pl"

run_rc_command "\$1"
RCD
chmod +x "/usr/local/etc/rc.d/$TTYD_SERVICE_NAME"

# Enable in rc.conf
sysrc "$SERVICE_NAME"_enable=YES
sysrc "$TTYD_SERVICE_NAME"_enable=YES
sysrc "$TTYD_SERVICE_NAME"_user="$WEB_USER"
sysrc "$TTYD_SERVICE_NAME"_pass="$WEB_PASS"
sysrc "$TTYD_SERVICE_NAME"_port="$CLUSTER_SYSOP_PORT"

ok "rc.d services installed."

# =============================================================================
#  Step 8: Start the services
# =============================================================================
info "Starting DXSpider cluster..."
service "$SERVICE_NAME" start

info "Starting web console..."
service "$TTYD_SERVICE_NAME" start

# =============================================================================
#  Step 9: Verify
# =============================================================================
info "Waiting for cluster to listen on port $CLUSTER_PORT..."
for i in $(seq 1 30); do
    if nc -z localhost "$CLUSTER_PORT" 2>/dev/null; then
        ok "DXSpider is listening on port $CLUSTER_PORT"
        break
    fi
    sleep 1
    [ "$i" -eq 30 ] && warn "Cluster did not start within 30s. Check: tail -f $SPIDER_DIR/data/log/*.log"
done

# =============================================================================
#  Done
# =============================================================================
HOST_IP=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
[ -z "$HOST_IP" ] && HOST_IP="localhost"

echo ""
echo "$(c_green '========================================')"
echo "$(c_green '  FreeBSD installation complete!')"
echo "$(c_green '========================================')"
echo ""
echo "  Telnet:        $(c_bold "telnet $HOST_IP $CLUSTER_PORT")"
echo "  Web Console:   $(c_bold "http://$HOST_IP:$CLUSTER_SYSOP_PORT")"
echo "                 (login: $WEB_USER / password: the one you set above)"
echo ""
echo "  Install dir:   $(c_bold "$SPIDER_DIR")"
echo "  Config:        $(c_bold "$SPIDER_DIR/local/DXVars.pm")"
echo ""
echo "  Service commands:"
echo "    service $SERVICE_NAME start|stop|restart|status"
echo "    service $TTYD_SERVICE_NAME start|stop|restart|status"
echo ""
echo "  Enable on boot (already set):"
echo "    sysrc $SERVICE_NAME_enable=YES"
echo "    sysrc $TTYD_SERVICE_NAME_enable=YES"
echo ""
echo "  Edit config:   nano $SPIDER_DIR/local/DXVars.pm"
echo "                 (then: service $SERVICE_NAME restart)"
echo ""
echo "  Logs:          tail -f $SPIDER_DIR/data/log/*.log"
echo ""
echo "  73 and Good DX! — 9M2PJU"
echo ""
