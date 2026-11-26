#!/usr/bin/env bash
#
# 9M2PJU DXSpider Docker - Interactive Installation Script
# https://github.com/9M2PJU/9M2PJU-DXSpider-Docker
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install.sh | bash
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

generate_password() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20
    else
        LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20
    fi
}

echo -e "${CYAN}==========================================================================${NC}"
echo -e "${CYAN}                   9M2PJU DXSpider Docker Installer${NC}"
echo -e "${CYAN}==========================================================================${NC}"
echo ""

# 1. Check prerequisites
command -v git >/dev/null 2>&1 || { echo -e "${RED}Error: git is required but it's not installed. Aborting.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is required but it's not installed. Aborting.${NC}" >&2; exit 1; }

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    echo -e "${YELLOW}Warning: Legacy docker-compose detected. Docker Compose V2 ('docker compose') is recommended.${NC}"
else
    echo -e "${RED}Error: docker compose is required but it's not installed. Aborting.${NC}" >&2
    exit 1
fi

# 2. Choose directory
DEFAULT_DIR="$HOME/9M2PJU-DXSpider-Docker"
echo -e "${YELLOW}Where would you like to install?${NC}"
read -r -p "Directory [$DEFAULT_DIR]: " INSTALL_DIR </dev/tty
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

if [ -d "$INSTALL_DIR" ]; then
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists and appears to be a git repository.${NC}"
    else
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists.${NC}"
    fi
    read -r -p "Do you want to continue using this directory? [y/N]: " PROCEED </dev/tty
    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
else
    echo -e "${GREEN}Cloning repository to $INSTALL_DIR...${NC}"
    git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Ensure we have .env.example
if [ ! -f ".env.example" ]; then
    echo -e "${RED}Error: .env.example not found in $INSTALL_DIR.${NC}" >&2
    exit 1
fi

# 3. Prompt for configuration
echo ""
echo -e "${CYAN}--- Node Configuration ---${NC}"
echo "Please provide the following details for your DXSpider node."
echo "Press Enter to accept the [defaults]."
echo ""

read -r -p "Cluster Callsign (e.g., N0CALL-2) [N0CALL-2]: " CLUSTER_CALLSIGN </dev/tty
CLUSTER_CALLSIGN=$(printf '%s' "${CLUSTER_CALLSIGN:-N0CALL-2}" | tr 'a-z' 'A-Z')

read -r -p "Sysop Callsign (e.g., 9M2PJU) [9M2PJU]: " CLUSTER_SYSOP_CALLSIGN </dev/tty
CLUSTER_SYSOP_CALLSIGN=$(printf '%s' "${CLUSTER_SYSOP_CALLSIGN:-9M2PJU}" | tr 'a-z' 'A-Z')

read -r -p "Grid Locator (e.g., OJ03UD) [OJ03UD]: " CLUSTER_LOCATOR </dev/tty
CLUSTER_LOCATOR=$(printf '%s' "${CLUSTER_LOCATOR:-OJ03UD}" | tr 'a-z' 'A-Z')

read -r -p "Station QTH (e.g., Kuala Lumpur, Malaysia) [DXSpider Node]: " CLUSTER_QTH </dev/tty
CLUSTER_QTH=${CLUSTER_QTH:-"DXSpider Node"}

read -r -p "Sysop Email [sysop@localhost]: " CLUSTER_SYSOP_EMAIL </dev/tty
CLUSTER_SYSOP_EMAIL=${CLUSTER_SYSOP_EMAIL:-"sysop@localhost"}

AUTO_PASS=$(generate_password)
read -r -p "Web Console Password [auto-generated strong password]: " WEB_PASS </dev/tty
WEB_PASS=${WEB_PASS:-$AUTO_PASS}

# 4. Generate .env safely (avoiding sed delimiter/escaping issues)
echo ""
echo -e "${GREEN}Generating .env file...${NC}"

if [ -f ".env" ]; then
    cp ".env" ".env.bak.$(date +%F-%H%M%S)"
    echo -e "${YELLOW}Existing .env backed up before overwriting.${NC}"
fi

cp .env.example .env

set_env_var() {
    local key="$1"
    local val="$2"
    local tmpfile
    tmpfile=$(mktemp)
    awk -v k="$key" -v v="$val" '
        BEGIN { replaced = 0 }
        $0 ~ ("^" k "=") { print k "=" v; replaced = 1; next }
        { print }
        END { if (!replaced) print k "=" v }
    ' .env > "$tmpfile"
    mv "$tmpfile" .env
}

set_env_var "CLUSTER_CALLSIGN" "$CLUSTER_CALLSIGN"
set_env_var "CLUSTER_SYSOP_CALLSIGN" "$CLUSTER_SYSOP_CALLSIGN"
set_env_var "CLUSTER_LOCATOR" "$CLUSTER_LOCATOR"
set_env_var "CLUSTER_QTH" "$CLUSTER_QTH"
set_env_var "CLUSTER_SYSOP_EMAIL" "$CLUSTER_SYSOP_EMAIL"
set_env_var "WEB_PASS" "$WEB_PASS"
chmod 600 .env

echo -e "${GREEN}.env configured successfully! (permissions set to 600)${NC}"

# 5. Start container?
echo ""
read -r -p "Do you want to pull the image and start the cluster now? [Y/n]: " START_NOW </dev/tty
START_NOW=${START_NOW:-Y}

if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Pulling image...${NC}"
    $COMPOSE_CMD pull
    echo -e "${GREEN}Starting cluster...${NC}"
    $COMPOSE_CMD up -d

    echo ""
    echo -e "${CYAN}==========================================================================${NC}"
    echo -e "${GREEN} DXSpider is now running!${NC}"
    echo ""
    echo -e " Telnet:      ${YELLOW}localhost 7300${NC}"
    echo -e " Web Console: ${YELLOW}http://127.0.0.1:8080${NC} (User: sysop, Pass: $WEB_PASS)"
    echo -e "              (Bound to localhost by default; set WEB_BIND_ADDRESS=0.0.0.0"
    echo -e "               in .env or use an SSH tunnel for remote access.)"
    echo -e "${CYAN}==========================================================================${NC}"
    echo "Note: Check logs anytime with '$COMPOSE_CMD logs -f' and upgrade with './upgrade.sh'"
else
    echo ""
    echo -e "${CYAN}==========================================================================${NC}"
    echo -e "${GREEN} Installation complete.${NC}"
    echo ""
    echo -e " Generated Web Console password: ${YELLOW}$WEB_PASS${NC}"
    echo -e " To start the cluster later, run:"
    echo -e "   ${YELLOW}cd $INSTALL_DIR${NC}"
    echo -e "   ${YELLOW}$COMPOSE_CMD up -d${NC}"
    echo -e "${CYAN}==========================================================================${NC}"
fi
