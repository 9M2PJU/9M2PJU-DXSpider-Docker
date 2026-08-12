#!/usr/bin/env bash
#
# 9M2PJU DXSpider Docker - Interactive Installation Script
# https://github.com/9M2PJU/9M2PJU-DXSpider-Docker
#
# Usage:
# curl -sSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==========================================================================${NC}"
echo -e "${CYAN}                   9M2PJU DXSpider Docker Installer${NC}"
echo -e "${CYAN}==========================================================================${NC}"
echo ""

# 1. Check prerequisites
command -v git >/dev/null 2>&1 || { echo -e "${RED}Error: git is required but it's not installed. Aborting.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is required but it's not installed. Aborting.${NC}" >&2; exit 1; }

COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}Error: docker compose (or docker-compose) is required but it's not installed. Aborting.${NC}" >&2
    exit 1
fi

# 2. Choose directory
DEFAULT_DIR="$HOME/9M2PJU-DXSpider-Docker"
echo -e "${YELLOW}Where would you like to install?${NC}"
read -p "Directory [$DEFAULT_DIR]: " INSTALL_DIR </dev/tty
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

if [ -d "$INSTALL_DIR" ]; then
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists and appears to be a git repository.${NC}"
    else
        echo -e "${YELLOW}Directory $INSTALL_DIR already exists.${NC}"
    fi
    read -p "Do you want to continue using this directory? [y/N]: " PROCEED </dev/tty
    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
else
    echo -e "${GREEN}Cloning repository to $INSTALL_DIR...${NC}"
    git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Ensure we have the .env.example
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

read -p "Cluster Callsign (e.g., N0CALL-2) [N0CALL-2]: " CLUSTER_CALLSIGN </dev/tty
CLUSTER_CALLSIGN=${CLUSTER_CALLSIGN:-N0CALL-2}

read -p "Sysop Callsign (e.g., 9M2PJU) [9M2PJU]: " CLUSTER_SYSOP_CALLSIGN </dev/tty
CLUSTER_SYSOP_CALLSIGN=${CLUSTER_SYSOP_CALLSIGN:-9M2PJU}

read -p "Grid Locator (e.g., OJ03UD) [OJ03UD]: " CLUSTER_LOCATOR </dev/tty
CLUSTER_LOCATOR=${CLUSTER_LOCATOR:-OJ03UD}

read -p "Web Console Password [changeme-web]: " WEB_PASS </dev/tty
WEB_PASS=${WEB_PASS:-changeme-web}

# 4. Generate .env
echo ""
echo -e "${GREEN}Generating .env file...${NC}"

sed -e "s|^CLUSTER_CALLSIGN=.*|CLUSTER_CALLSIGN=${CLUSTER_CALLSIGN}|" \
    -e "s|^CLUSTER_SYSOP_CALLSIGN=.*|CLUSTER_SYSOP_CALLSIGN=${CLUSTER_SYSOP_CALLSIGN}|" \
    -e "s|^CLUSTER_LOCATOR=.*|CLUSTER_LOCATOR=${CLUSTER_LOCATOR}|" \
    -e "s|^WEB_PASS=.*|WEB_PASS=${WEB_PASS}|" \
    .env.example > .env

echo -e "${GREEN}.env configured successfully!${NC}"

# 5. Start container?
echo ""
read -p "Do you want to pull the image and start the cluster now? [Y/n]: " START_NOW </dev/tty
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
    echo -e " Web Console: ${YELLOW}http://localhost:8080${NC} (User: sysop, Pass: $WEB_PASS)"
    echo -e "${CYAN}==========================================================================${NC}"
    echo "Note: You can check the logs anytime with '$COMPOSE_CMD logs -f'"
else
    echo ""
    echo -e "${CYAN}==========================================================================${NC}"
    echo -e "${GREEN} Installation complete.${NC}"
    echo ""
    echo -e " To start the cluster later, run:"
    echo -e "   ${YELLOW}cd $INSTALL_DIR${NC}"
    echo -e "   ${YELLOW}$COMPOSE_CMD up -d${NC}"
    echo -e "${CYAN}==========================================================================${NC}"
fi
