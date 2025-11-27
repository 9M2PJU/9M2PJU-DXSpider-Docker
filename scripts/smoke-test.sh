#!/bin/bash
#
# Smoke Test Script for DXSpider Docker Container
#
# This script performs basic smoke tests to verify the container builds
# and runs correctly. It tests:
# - Container startup
# - Health check status
# - Telnet port connectivity
# - Web console port connectivity
# - DXSpider process running
# - Log file creation
#
# Usage: ./scripts/smoke-test.sh
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
CONTAINER_NAME="dxspider-test"
IMAGE_NAME="${IMAGE_NAME:-test:latest}"
TELNET_PORT="${CLUSTER_PORT:-7300}"
WEB_PORT="${CLUSTER_SYSOP_PORT:-8050}"
MAX_WAIT_TIME=60
HEALTH_CHECK_INTERVAL=5

# Log file
LOG_FILE="/tmp/test-smoke-$(date +%Y%m%d-%H%M%S).log"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    docker stop "$CONTAINER_NAME" 2>&1 | tee -a "$LOG_FILE" || true
    docker rm "$CONTAINER_NAME" 2>&1 | tee -a "$LOG_FILE" || true
    echo "Cleanup complete" | tee -a "$LOG_FILE"
}

# Trap EXIT to ensure cleanup
trap cleanup EXIT

# Print functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}" | tee -a "$LOG_FILE"
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_command="$2"

    print_info "Running: $test_name"

    if eval "$test_command"; then
        print_success "$test_name"
        return 0
    else
        print_error "$test_name"
        return 1
    fi
}

# Check if required commands exist
check_dependencies() {
    local missing_deps=()

    for cmd in docker nc timeout; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_deps[*]}"
        exit 1
    fi
}

# Start container
start_container() {
    print_info "Starting DXSpider container..."

    # Use test environment file if it exists, otherwise create minimal config
    if [ -f ".env.test" ]; then
        ENV_FILE=".env.test"
    else
        cat > /tmp/test.env << EOF
CLUSTER_CALLSIGN=TEST-99
CLUSTER_DXSPIDER_BRANCH=mojo
CLUSTER_SYSOP_NAME=Test Sysop
CLUSTER_SYSOP_CALLSIGN=TEST
CLUSTER_SYSOP_EMAIL=test@example.com
CLUSTER_SYSOP_BBS_ADDRESS=TEST@WW
CLUSTER_LATITUDE=+51.5
CLUSTER_LONGITUDE=-0.13
CLUSTER_LOCATOR=JO01AA
CLUSTER_QTH=Test Location
CLUSTER_DX_HOSTNAME=test.example.com
CLUSTER_PORT=$TELNET_PORT
CLUSTER_SYSOP_PORT=$WEB_PORT
CLUSTER_DB_USER=sysop
CLUSTER_DB_PASS=testpass
EOF
        ENV_FILE="/tmp/test.env"
    fi

    docker run -d \
        --name "$CONTAINER_NAME" \
        --env-file "$ENV_FILE" \
        -p "$TELNET_PORT:$TELNET_PORT" \
        -p "$WEB_PORT:$WEB_PORT" \
        "$IMAGE_NAME" 2>&1 | tee -a "$LOG_FILE"

    if [ $? -eq 0 ]; then
        print_success "Container started successfully"
        return 0
    else
        print_error "Failed to start container"
        return 1
    fi
}

# Wait for container to be healthy
wait_for_health() {
    print_info "Waiting for container to become healthy (max ${MAX_WAIT_TIME}s)..."

    local elapsed=0

    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        # Check if container is still running
        if ! docker ps | grep -q "$CONTAINER_NAME"; then
            print_error "Container stopped unexpectedly"
            docker logs "$CONTAINER_NAME" 2>&1 | tail -20 | tee -a "$LOG_FILE"
            return 1
        fi

        # Get health status
        HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")

        if [ "$HEALTH_STATUS" = "healthy" ]; then
            print_success "Container is healthy after ${elapsed}s"
            return 0
        fi

        if [ "$HEALTH_STATUS" = "unhealthy" ]; then
            print_error "Container is unhealthy"
            docker logs "$CONTAINER_NAME" 2>&1 | tail -20 | tee -a "$LOG_FILE"
            return 1
        fi

        echo -n "." | tee -a "$LOG_FILE"
        sleep $HEALTH_CHECK_INTERVAL
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
    done

    echo "" | tee -a "$LOG_FILE"
    print_error "Timeout waiting for container to become healthy"
    return 1
}

# Test telnet port connectivity
test_telnet_port() {
    print_info "Testing telnet port ($TELNET_PORT) connectivity..."

    if timeout 5 nc -zv localhost "$TELNET_PORT" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Telnet port is accessible"
        return 0
    else
        print_error "Cannot connect to telnet port"
        return 1
    fi
}

# Test web console port connectivity
test_web_port() {
    print_info "Testing web console port ($WEB_PORT) connectivity..."

    if timeout 5 nc -zv localhost "$WEB_PORT" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Web console port is accessible"
        return 0
    else
        print_error "Cannot connect to web console port"
        return 1
    fi
}

# Test DXSpider process is running
test_process_running() {
    print_info "Checking if DXSpider process is running..."

    if docker exec "$CONTAINER_NAME" pgrep -f "cluster.pl" > /dev/null 2>&1; then
        print_success "DXSpider process is running"

        # Show process details
        docker exec "$CONTAINER_NAME" ps aux | grep -E "(cluster.pl|ttyd)" | grep -v grep | tee -a "$LOG_FILE"
        return 0
    else
        print_error "DXSpider process not found"
        docker exec "$CONTAINER_NAME" ps aux | tee -a "$LOG_FILE"
        return 1
    fi
}

# Test configuration files were generated
test_config_files() {
    print_info "Checking if configuration files were generated..."

    local missing_files=()

    for file in "/spider/local/DXVars.pm" "/spider/local/Listeners.pm"; do
        if ! docker exec "$CONTAINER_NAME" test -f "$file"; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        print_success "All configuration files exist"
        return 0
    else
        print_error "Missing configuration files: ${missing_files[*]}"
        return 1
    fi
}

# Test log files are being created
test_log_files() {
    print_info "Checking if log files are being created..."

    # Wait a bit for logs to be generated
    sleep 3

    if docker exec "$CONTAINER_NAME" sh -c "ls -la /spider/local_data/*.log 2>/dev/null || ls -la /spider/local_data/log/ 2>/dev/null" | tee -a "$LOG_FILE"; then
        print_success "Log files are being created"
        return 0
    else
        print_error "No log files found"
        return 1
    fi
}

# Test basic telnet interaction
test_telnet_interaction() {
    print_info "Testing basic telnet interaction..."

    # Try to connect and send a basic command
    if echo "quit" | timeout 5 nc localhost "$TELNET_PORT" > /tmp/telnet-response.txt 2>&1; then
        if grep -q -E "(login:|DXSpider|callsign)" /tmp/telnet-response.txt; then
            print_success "Telnet interaction successful"
            cat /tmp/telnet-response.txt | tee -a "$LOG_FILE"
            rm -f /tmp/telnet-response.txt
            return 0
        fi
    fi

    print_error "Telnet interaction failed or unexpected response"
    cat /tmp/telnet-response.txt 2>/dev/null | tee -a "$LOG_FILE"
    rm -f /tmp/telnet-response.txt
    return 1
}

# Display container logs
show_container_logs() {
    print_info "Container logs (last 30 lines):"
    docker logs --tail 30 "$CONTAINER_NAME" 2>&1 | tee -a "$LOG_FILE"
}

# Main test execution
main() {
    echo "========================================" | tee "$LOG_FILE"
    echo "DXSpider Container Smoke Tests" | tee -a "$LOG_FILE"
    echo "$(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    local failed_tests=0

    # Check dependencies
    print_info "Checking dependencies..."
    check_dependencies || exit 1

    # Start container
    start_container || exit 1

    # Run tests
    run_test "Wait for container health check" wait_for_health || ((failed_tests++))
    run_test "Test DXSpider process running" test_process_running || ((failed_tests++))
    run_test "Test configuration files" test_config_files || ((failed_tests++))
    run_test "Test telnet port connectivity" test_telnet_port || ((failed_tests++))
    run_test "Test web console port connectivity" test_web_port || ((failed_tests++))
    run_test "Test log files creation" test_log_files || ((failed_tests++))
    run_test "Test telnet interaction" test_telnet_interaction || ((failed_tests++))

    # Show logs
    echo "" | tee -a "$LOG_FILE"
    show_container_logs

    # Summary
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "Test Summary" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    if [ $failed_tests -eq 0 ]; then
        print_success "All smoke tests passed!"
        echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
        exit 0
    else
        print_error "$failed_tests test(s) failed"
        echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Run main function
main "$@"
