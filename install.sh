#!/bin/bash
# =============================================================================
#  9M2PJU DXSpider Docker — One-line installer
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install.sh | bash
#
#  Or clone and run locally:
#    bash install.sh
#
#  What this script does:
#    1. Detects your OS:
#       - Linux: installs Docker if missing (Debian, Ubuntu, Fedora, CentOS,
#         RHEL, Rocky, Alma, Alpine, Arch), then uses docker compose
#       - WSL2: uses Docker Desktop's WSL integration (Docker Desktop must be
#         installed and running on Windows), then uses docker compose
#       - macOS: installs Docker Desktop via Homebrew if missing, then uses
#         docker compose (Docker Desktop runs a Linux VM under the hood)
#       - FreeBSD: branches to install-freebsd.sh (native install, no Docker)
#    2. Clones the repo to /opt/dxspider on Linux/FreeBSD or ~/dxspider on
#       WSL2/macOS
#    3. Interactively prompts for your callsign, sysop callsign, locator, QTH
#    4. Generates a .env file from your answers
#    5. Pulls the pre-built image and starts the cluster with `docker compose up -d`
#    6. Prints the telnet + web console URLs
#
#  Re-run safely — existing .env is backed up, not overwritten.
# =============================================================================
set -euo pipefail

is_wsl() {
    [ "$(uname -s)" = "Linux" ] || return 1
    [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
    grep -qiE 'microsoft|wsl' /proc/version /proc/sys/kernel/osrelease 2>/dev/null
}

# --- Config ---
REPO_URL="https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git"
# Default install dir: /opt/dxspider on Linux/FreeBSD, ~/dxspider on WSL2/macOS
# (macOS users typically don't have /opt writable without root)
if [ "$(uname -s)" = "Darwin" ] || is_wsl; then
    INSTALL_DIR="${INSTALL_DIR:-$HOME/dxspider}"
else
    INSTALL_DIR="${INSTALL_DIR:-/opt/dxspider}"
fi
BRANCH="main"

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
    # prompt "question" "default" -> prints user input or default
    local question="$1" default="${2:-}" var
    if [ -n "$default" ]; then
        printf "%s %s [%s]: " "$(c_bold '?')" "$question" "$default"
    else
        printf "%s %s: " "$(c_bold '?')" "$question"
    fi
    if [ -r /dev/tty ]; then
        read -r var </dev/tty
    else
        read -r var
    fi
    echo "${var:-$default}"
}

require_root_for_docker_install() {
    # Docker Desktop is installed outside the Linux distro on macOS/WSL2.
    if [ "$(uname -s)" = "Darwin" ] || is_wsl; then
        return
    fi
    if [ "$(id -u)" -ne 0 ]; then
        warn "Docker is not installed. Re-running with sudo to install it."
        exec sudo -E bash "$0" "$@"
    fi
}

# --- Detect OS ---
detect_os() {
    # WSL2 uses Docker Desktop's daemon instead of a Linux daemon in the distro.
    if is_wsl; then
        echo "wsl"
        return
    fi
    # macOS / Darwin
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "macos"
        return
    fi
    # Linux distros
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${ID:-unknown}"
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

# --- Check / install Docker ---
have_docker() {
    command -v docker >/dev/null 2>&1
}

have_compose() {
    docker compose version >/dev/null 2>&1
}

docker_daemon_ready() {
    docker info >/dev/null 2>&1
}

install_docker_wsl() {
    die "WSL detected, but Docker Desktop is not available. Install Docker Desktop for Windows, enable the WSL2 backend and WSL integration, start Docker Desktop, then run this command again."
}

install_docker() {
    local os
    os="$(detect_os)"
    info "Detected OS: $os"
    case "$os" in
        wsl)
            install_docker_wsl
            return
            ;;
        macos)
            install_docker_macos
            return
            ;;
        debian|ubuntu|linuxmint|pop)
            info "Installing Docker via official apt repository..."
            apt-get update -y
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg \
                | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            # shellcheck disable=SC1091
            . /etc/os-release
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$ID $VERSION_CODENAME stable" \
                > /etc/apt/sources.list.d/docker.list
            apt-get update -y
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        fedora)
            info "Installing Docker via dnf..."
            dnf install -y dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|rocky|almalinux)
            info "Installing Docker via dnf..."
            dnf install -y dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        alpine)
            info "Installing Docker via apk..."
            apk add --no-cache docker docker-cli-compose
            ;;
        arch|manjaro|garuda|cachyos)
            info "Installing Docker via pacman..."
            pacman -Sy --noconfirm docker docker-compose
            ;;
        *)
            die "Unsupported OS '$os' for automatic Docker install.
Please install Docker manually: https://docs.docker.com/engine/install/
Then re-run this script."
            ;;
    esac
    systemctl enable --now docker 2>/dev/null || true
}

# --- macOS: install Docker Desktop via Homebrew ---
install_docker_macos() {
    # Homebrew is required to install Docker Desktop automatically
    if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew (the macOS package manager)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for this session (Homebrew installs to /opt/homebrew on Apple Silicon,
        # /usr/local on Intel)
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        command -v brew >/dev/null 2>&1 || die "Homebrew install failed. Install manually from https://brew.sh and re-run."
    fi

    info "Installing Docker Desktop via Homebrew..."
    brew install --cask docker

    # Docker Desktop needs to be launched manually the first time (it runs a
    # Linux VM in the background). The `docker` CLI won't work until the GUI
    # app has been started and the user has accepted the license agreement.
    ok "Docker Desktop installed."
    echo ""
    warn "Docker Desktop must be started manually the first time:"
    warn "  1. Open 'Docker' from Applications (or: open -a Docker)"
    warn "  2. Accept the license agreement in the GUI"
    warn "  3. Wait for the Docker whale icon in the menu bar to stop animating"
    warn "  4. Re-run this script to continue:"
    warn "     bash install.sh"
    echo ""
    die "Docker Desktop installed but not yet running. Start it, then re-run this script."
}

ensure_docker_group() {
    # Docker Desktop handles permissions on macOS/WSL2 — no Linux group needed.
    if [ "$(uname -s)" = "Darwin" ] || is_wsl; then
        return
    fi
    # Add current user to docker group so they can run docker without sudo
    local user
    user="$(id -un)"
    if getent group docker >/dev/null 2>&1 && ! id -nG "$user" | grep -qw docker; then
        info "Adding user '$user' to the 'docker' group..."
        usermod -aG docker "$user" 2>/dev/null || true
        warn "You may need to log out and back in (or run 'newgrp docker') for docker access without sudo."
    fi
}

# =============================================================================
#  Main
# =============================================================================
echo ""
echo "$(c_bold '========================================')"
echo "$(c_bold '  9M2PJU DXSpider Docker — Installer')"
echo "$(c_bold '========================================')"
echo ""

# --- Detect FreeBSD and branch to the native installer ---
# Docker does NOT run on FreeBSD (requires Linux cgroups/namespaces).
# The FreeBSD installer installs DXSpider natively via pkg + p5-* Perl modules.
if [ "$(uname -s)" = "FreeBSD" ]; then
    info "FreeBSD detected — Docker is not available on FreeBSD."
    info "Switching to the native FreeBSD installer (no Docker, no container)..."

    # If running from a clone, use the local script. Otherwise download it.
    SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo .)"
    if [ -f "$SCRIPT_DIR/install-freebsd.sh" ]; then
        exec bash "$SCRIPT_DIR/install-freebsd.sh" "$@"
    else
        exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install-freebsd.sh)"
    fi
fi

# --- Step 1: Docker ---
if have_docker && have_compose; then
    ok "Docker + Docker Compose detected."
else
    if have_docker && ! have_compose; then
        warn "Docker found, but 'docker compose' plugin is missing."
        die "Install the docker-compose-plugin package, then re-run this script.
See: https://docs.docker.com/compose/install/"
    fi
    require_root_for_docker_install "$@"
    install_docker
    have_docker || die "Docker install failed."
    have_compose || die "docker compose plugin not available after install."
    ok "Docker installed successfully."
fi

if ! docker_daemon_ready; then
    if is_wsl; then
        die "Docker Desktop is installed but not running or WSL integration is disabled. Start Docker Desktop, enable Settings > Resources > WSL Integration for this distro, then re-run the installer."
    fi
    die "The Docker daemon is not running. Start Docker, then re-run the installer."
fi

# Drop root if we were elevated only for Docker install
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    info "Dropping back to user '$SUDO_USER'..."
    exec sudo -u "$SUDO_USER" -E bash "$0" "$@"
fi

ensure_docker_group

# --- Step 2: Clone / update repo ---
if [ -d "$INSTALL_DIR/.git" ]; then
    info "Existing install found at $INSTALL_DIR — updating..."
    git -C "$INSTALL_DIR" fetch --quiet origin "$BRANCH"
    git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH" --quiet
    ok "Updated to latest."
else
    info "Cloning 9M2PJU DXSpider Docker to $INSTALL_DIR ..."
    if [ -d "$INSTALL_DIR" ] && [ ! -d "$INSTALL_DIR/.git" ]; then
        warn "$INSTALL_DIR exists but is not a git repo. Backing it up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
    fi
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_DIR"
    ok "Cloned."
fi
cd "$INSTALL_DIR"

# --- Step 3: Generate .env (interactive) ---
ENV_FILE="$INSTALL_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    warn "An existing .env was found. Backing up to .env.bak.$(date +%s)"
    cp "$ENV_FILE" "$ENV_FILE.bak.$(date +%s)"
fi

echo ""
echo "$(c_bold 'Configuration')"
echo "Please answer the following. Press Enter to accept the [default]."
echo ""

CLUSTER_CALLSIGN=$(prompt "Node callsign (SSID allowed, e.g. -2)" "N0CALL-2")
CLUSTER_SYSOP_CALLSIGN=$(prompt "Your sysop callsign" "9M2PJU")
CLUSTER_SYSOP_NAME=$(prompt "Your name" "Sysop")
CLUSTER_LOCATOR=$(prompt "Maidenhead grid locator (find at amsat.org/tools/grid-square-locator)" "OJ03UD")
CLUSTER_QTH=$(prompt "QTH description (city, country)" "Kuala Lumpur, Malaysia")
CLUSTER_LATITUDE=$(prompt "Latitude (decimal degrees, +N/-S)" "+03.08")
CLUSTER_LONGITUDE=$(prompt "Longitude (decimal degrees, +E/-W)" "+101.41")
CLUSTER_SYSOP_EMAIL=$(prompt "Contact email (shown to users)" "9m2pju@hamradio.my")
CLUSTER_PORT=$(prompt "Telnet port" "7300")
CLUSTER_SYSOP_PORT=$(prompt "Web console port" "8080")
WEB_USER=$(prompt "Web console username" "sysop")
WEB_PASS=$(prompt "Web console password (CHANGE THIS!)" "$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)")

# Uppercase callsigns/locator
CLUSTER_CALLSIGN=$(echo "$CLUSTER_CALLSIGN" | tr 'a-z' 'A-Z')
CLUSTER_SYSOP_CALLSIGN=$(echo "$CLUSTER_SYSOP_CALLSIGN" | tr 'a-z' 'A-Z')
CLUSTER_LOCATOR=$(echo "$CLUSTER_LOCATOR" | tr 'a-z' 'A-Z')

if [ "$CLUSTER_CALLSIGN" = "$CLUSTER_SYSOP_CALLSIGN" ]; then
    die "Node callsign and sysop callsign must be different. For example: node ${CLUSTER_SYSOP_CALLSIGN}-2 and sysop ${CLUSTER_SYSOP_CALLSIGN}."
fi

cat > "$ENV_FILE" <<EOF
# Generated by install.sh on $(date)
# Edit manually with: nano $INSTALL_DIR/.env

CLUSTER_CALLSIGN=$CLUSTER_CALLSIGN
CLUSTER_DXSPIDER_BRANCH=mojo

CLUSTER_SYSOP_NAME=$CLUSTER_SYSOP_NAME
CLUSTER_SYSOP_CALLSIGN=$CLUSTER_SYSOP_CALLSIGN
CLUSTER_SYSOP_PASSWORD=

CLUSTER_LOCATOR=$CLUSTER_LOCATOR
CLUSTER_LATITUDE=$CLUSTER_LATITUDE
CLUSTER_LONGITUDE=$CLUSTER_LONGITUDE
CLUSTER_QTH=$CLUSTER_QTH

CLUSTER_SYSOP_EMAIL=$CLUSTER_SYSOP_EMAIL
CLUSTER_SYSOP_BBS_ADDRESS=

CLUSTER_PORT=$CLUSTER_PORT
CLUSTER_SYSOP_PORT=$CLUSTER_SYSOP_PORT

WEB_USER=$WEB_USER
WEB_PASS=$WEB_PASS

OVERWRITE_CONFIG=no
EOF

ok ".env written to $ENV_FILE"

# --- Step 4: Pull + start ---
info "Pulling pre-built image (this may take a minute)..."
docker compose pull

info "Starting DXSpider cluster..."
docker compose up -d

# --- Step 5: Verify ---
info "Waiting for cluster to start listening on port $CLUSTER_PORT..."
cluster_ready=0
for i in $(seq 1 30); do
    if docker compose exec -T dxspider nc -z localhost "$CLUSTER_PORT" 2>/dev/null; then
        ok "DXSpider is listening on port $CLUSTER_PORT"
        cluster_ready=1
        break
    fi
    sleep 1
done

if [ "$cluster_ready" -ne 1 ]; then
    warn "Cluster did not start listening within 30 seconds. Current status and logs:"
    docker compose ps -a || true
    docker compose logs --tail=100 dxspider || true
    die "DXSpider did not start. Fix the error above, then run: docker compose up -d"
fi

# --- Done ---
if is_wsl; then
    HOST_IP="localhost"
else
    HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
fi
echo ""
echo "$(c_green '========================================')"
echo "$(c_green '  Installation complete!')"
echo "$(c_green '========================================')"
echo ""
echo "  Telnet:        $(c_bold "telnet $HOST_IP $CLUSTER_PORT")"
echo "  Web Console:   $(c_bold "http://$HOST_IP:$CLUSTER_SYSOP_PORT")"
echo "                 (login: $WEB_USER / password: the one you set above)"
echo ""
echo "  Config file:   $(c_bold "$ENV_FILE")"
echo "  Install dir:   $(c_bold "$INSTALL_DIR")"
echo ""
echo "  Useful commands:"
echo "    cd $INSTALL_DIR"
echo "    docker compose logs -f dxspider    # follow logs"
echo "    docker compose exec dxspider sh    # shell into container"
echo "    docker compose restart             # restart"
echo "    docker compose down                # stop"
echo ""
echo "  Edit config:   nano $ENV_FILE  (then: docker compose restart)"
echo ""
echo "  73 and Good DX! — 9M2PJU"
echo ""
