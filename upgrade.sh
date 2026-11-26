#!/usr/bin/env bash
# =============================================================================
#  9M2PJU DXSpider Docker - Safe Upgrade Script
#  https://github.com/9M2PJU/9M2PJU-DXSpider-Docker
#
#  Usage:
#    ./upgrade.sh                  # Pull latest repo & GHCR image, backup, upgrade
#    ./upgrade.sh --build          # Build image locally (--no-cache) instead of pull
#    ./upgrade.sh --with-db        # Include optional MariaDB profile
#    ./upgrade.sh --no-git-pull    # Skip git pull (upgrade image only)
#    ./upgrade.sh --skip-backup    # Skip quiescent tar.gz backup
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BUILD_LOCAL=0
WITH_DB=0
SKIP_GIT_PULL=0
SKIP_BACKUP=0

for arg in "$@"; do
    case "$arg" in
        --build)       BUILD_LOCAL=1 ;;
        --with-db)     WITH_DB=1 ;;
        --no-git-pull) SKIP_GIT_PULL=1 ;;
        --skip-backup) SKIP_BACKUP=1 ;;
        -h|--help)
            sed -n '2,12p' "$0"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: ${arg}${NC}" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo -e "${CYAN}==========================================================================${NC}"
echo -e "${CYAN}                   9M2PJU DXSpider Docker Upgrader${NC}"
echo -e "${CYAN}==========================================================================${NC}"

# 1. Verify prerequisites
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is not installed.${NC}" >&2; exit 1; }
if ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker Compose V2 ('docker compose') is required.${NC}" >&2
    exit 1
fi

# Auto-detect MariaDB usage from .env if --with-db was not explicitly passed
if [ "${WITH_DB}" -eq 0 ] && [ -f .env ]; then
    if grep -Eq '^[[:space:]]*CLUSTER_DB_HOSTNAME[[:space:]]*=[[:space:]]*[^[:space:]#]+' .env; then
        WITH_DB=1
    fi
fi

# Warn if legacy docker-compose.yml exists alongside compose.yaml
if [ -f docker-compose.yml ] && [ -f compose.yaml ]; then
    echo -e "${YELLOW}Warning: Legacy docker-compose.yml detected alongside compose.yaml.${NC}"
    echo -e "${YELLOW}Migrate any custom settings into compose.yaml and remove docker-compose.yml.${NC}"
fi

# 2. Migrate legacy root-level config files into local_cmd/ and local_data/
mkdir -p local_cmd local_data connect msg

migrate_legacy_file() {
    local src="$1"
    local dst="$2"
    if [ -f "${src}" ] && [ ! -L "${src}" ] && [ ! -f "${dst}" ]; then
        echo -e "${YELLOW}Migrating legacy ${src} -> ${dst}${NC}"
        cp -p "${src}" "${dst}"
    fi
}

migrate_legacy_file "startup" "local_cmd/startup"
migrate_legacy_file "motd" "local_data/motd"
migrate_legacy_file "motd_nor" "local_data/motd_nor"

# 3. Pull repository updates (unless --no-git-pull)
if [ "${SKIP_GIT_PULL}" -eq 0 ] && [ -d .git ]; then
    echo -e "${GREEN}[1/6] Pulling latest repository changes...${NC}"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${YELLOW}Local tracked changes detected; stashing before git pull...${NC}"
        git stash push -m "dxspider-upgrade-$(date +%F-%H%M%S)"
        STASHED=1
    else
        STASHED=0
    fi
    git pull --ff-only || {
        echo -e "${RED}git pull failed. Resolve git state manually or run with --no-git-pull.${NC}" >&2
        exit 1
    }
    if [ "${STASHED}" -eq 1 ]; then
        echo -e "${YELLOW}Re-applying stashed local changes...${NC}"
        git stash pop || echo -e "${YELLOW}Note: Check 'git status' to resolve any stash conflicts.${NC}"
    fi
else
    echo -e "${YELLOW}[1/6] Skipping git pull.${NC}"
fi

# 4. Pre-pull or rebuild image while the cluster is still online
if [ "${BUILD_LOCAL}" -eq 1 ]; then
    echo -e "${GREEN}[2/6] Building updated image locally (--no-cache)...${NC}"
    docker compose build --no-cache dxspider
else
    echo -e "${GREEN}[2/6] Pre-pulling latest container image...${NC}"
    if [ "${WITH_DB}" -eq 1 ]; then
        docker compose --profile with-db pull
    else
        docker compose pull dxspider
    fi
fi

# 5. Stop DXSpider cleanly so SQLite (dxusers.db) flushes before backup
echo -e "${GREEN}[3/6] Stopping dxspider cleanly (flushing user DB)...${NC}"
docker compose stop dxspider || true

# 6. Take a quiescent backup in the parent directory
if [ "${SKIP_BACKUP}" -eq 0 ]; then
    BACKUP_FILE="../dxspider-backup-$(date +%F-%H%M%S).tar.gz"
    BACKUP_PATHS=()
    for p in .env local_data connect local_cmd msg; do
        [ -e "$p" ] && BACKUP_PATHS+=("$p")
    done
    echo -e "${GREEN}[4/6] Creating quiescent backup at ${BACKUP_FILE}...${NC}"
    tar czf "${BACKUP_FILE}" "${BACKUP_PATHS[@]}"
else
    echo -e "${YELLOW}[4/6] Skipping backup (--skip-backup).${NC}"
fi

# 7. Recreate container
echo -e "${GREEN}[5/6] Starting updated container...${NC}"
if [ "${WITH_DB}" -eq 1 ]; then
    docker compose --profile with-db up -d
else
    docker compose up -d --no-deps dxspider
fi

# 8. Wait for healthy status and verify version
echo -e "${GREEN}[6/6] Waiting for cluster healthcheck...${NC}"
HEALTHY=0
for i in $(seq 1 30); do
    CID=$(docker compose ps -q dxspider || true)
    if [ -n "${CID}" ]; then
        STATUS=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${CID}" 2>/dev/null || echo "unknown")
        if [ "${STATUS}" = "healthy" ]; then
            HEALTHY=1
            break
        fi
    fi
    sleep 2
done

VERSION=$(docker compose exec -T dxspider cat /spider/.version 2>/dev/null || echo "unknown")
echo ""
echo -e "${CYAN}==========================================================================${NC}"
if [ "${HEALTHY}" -eq 1 ]; then
    echo -e "${GREEN} Upgrade complete! DXSpider is UP and HEALTHY.${NC}"
else
    echo -e "${YELLOW} Container started, but healthcheck is still settling.${NC}"
    echo -e "${YELLOW} Check logs with: docker compose logs --tail 50 dxspider${NC}"
fi
echo -e " Installed DXSpider Mojo commit: ${YELLOW}${VERSION}${NC}"
echo -e " Verify live status:             ${YELLOW}docker compose ps${NC}"
echo -e " Reclaim old image space:        ${YELLOW}docker image prune -f${NC}"
echo -e "${CYAN}==========================================================================${NC}"
