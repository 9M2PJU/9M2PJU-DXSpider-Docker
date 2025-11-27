#!/bin/bash
#
# DXSpider Dashboard Startup Script
#
# Usage:
#   ./start.sh              # Start dashboard only
#   ./start.sh --build      # Rebuild and start
#   ./start.sh --stop       # Stop dashboard
#   ./start.sh --logs       # View logs
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Check if DXSpider is running
check_dxspider() {
    if ! docker compose -f "$PROJECT_ROOT/docker-compose.yml" ps | grep -q "dxspider.*running"; then
        warn "DXSpider is not running. Starting DXSpider first..."
        cd "$PROJECT_ROOT"
        docker compose up -d
        cd "$SCRIPT_DIR"
        info "Waiting for DXSpider to start..."
        sleep 5
    fi
}

# Start dashboard
start_dashboard() {
    info "Starting DXSpider Dashboard..."

    cd "$PROJECT_ROOT"

    if [ "$1" == "--build" ]; then
        info "Building dashboard image..."
        docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d --build
    else
        docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d
    fi

    info "Dashboard starting..."
    sleep 3

    # Get the port
    DASHBOARD_PORT=$(grep -E '^DASHBOARD_PORT=' "$PROJECT_ROOT/.env" 2>/dev/null | cut -d'=' -f2 || echo "8080")

    info "Dashboard should be available at: http://localhost:$DASHBOARD_PORT"
    info "Use './start.sh --logs' to view logs"
}

# Stop dashboard
stop_dashboard() {
    info "Stopping DXSpider Dashboard..."

    cd "$PROJECT_ROOT"
    docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml down

    info "Dashboard stopped."
}

# View logs
view_logs() {
    info "Viewing dashboard logs (Ctrl+C to exit)..."

    cd "$PROJECT_ROOT"
    docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml logs -f dashboard
}

# Main script
main() {
    check_docker

    case "${1:-}" in
        --build)
            check_dxspider
            start_dashboard --build
            ;;
        --stop)
            stop_dashboard
            ;;
        --logs)
            view_logs
            ;;
        --help|-h)
            echo "DXSpider Dashboard Startup Script"
            echo ""
            echo "Usage:"
            echo "  ./start.sh              Start dashboard"
            echo "  ./start.sh --build      Rebuild and start"
            echo "  ./start.sh --stop       Stop dashboard"
            echo "  ./start.sh --logs       View logs"
            echo "  ./start.sh --help       Show this help"
            ;;
        "")
            check_dxspider
            start_dashboard
            ;;
        *)
            error "Unknown option: $1"
            echo "Use './start.sh --help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
