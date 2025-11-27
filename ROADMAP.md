# Project Roadmap & Improvements

This document outlines planned improvements, security fixes, and future features for the 9M2PJU-DXSpider-Docker project.

## Table of Contents

- [Critical Security Fixes](#critical-security-fixes)
- [High-Priority Improvements](#high-priority-improvements)
- [Documentation Needs](#documentation-needs)
- [Future Features](#future-features)

---

## Critical Security Fixes

These issues should be addressed before any production deployment.

### 1. Remove Privileged Container Mode

**File**: `docker-compose.yml` line 12

**Current**:
```yaml
privileged: true
```

**Problem**: Grants ALL Linux capabilities to the container, allowing potential container escape and host system access. This violates the principle of least privilege and is unnecessary for DXSpider.

**Solution**: Remove `privileged: true` entirely. If specific capabilities are needed, use:
```yaml
cap_add:
  - NET_BIND_SERVICE  # Only if binding to ports < 1024
```

**Status**: [x] Completed

---

### 2. Protect Credentials from Version Control

**Files**: `.env`, missing `.gitignore`

**Problem**:
- `.env` file with passwords is committed to the repository
- No `.gitignore` to prevent accidental commits of sensitive data
- Database password `sysoppassword` visible in git history

**Solution**:
1. Create `.gitignore` to exclude sensitive files
2. Rename `.env` to `.env.example` with placeholder values
3. Document that users should copy to `.env` and customize

**Status**: [x] Completed

---

### 3. Fix World-Writable Permissions

**File**: `Dockerfile` line 87

**Current**:
```dockerfile
RUN chmod -R a+rwx /spider
```

**Problem**: Makes entire `/spider` directory writable by any user/process, negating earlier security-conscious permissions.

**Solution**:
```dockerfile
RUN chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR}
# Remove the chmod -R a+rwx line entirely
```

**Status**: [x] Completed

---

### 4. Hide Credentials from Process List

**File**: `entrypoint.sh` line 64

**Current**:
```bash
ttyd -p ${CLUSTER_SYSOP_PORT} -u 1000 -t fontSize=16 -c ${CLUSTER_DBUSER}:${CLUSTER_DBPASS} perl /spider/perl/console.pl
```

**Problem**: Credentials visible to anyone running `ps aux` on the host.

**Solution**: Use ttyd's credential file option or environment variable approach:
```bash
# Option 1: Use credential file
echo "${CLUSTER_DBUSER}:${CLUSTER_DBPASS}" > /tmp/.ttyd_creds
ttyd -p ${CLUSTER_SYSOP_PORT} -u 1000 -t fontSize=16 -c @/tmp/.ttyd_creds perl /spider/perl/console.pl

# Option 2: Disable auth if behind reverse proxy with auth
ttyd -p ${CLUSTER_SYSOP_PORT} -u 1000 -t fontSize=16 perl /spider/perl/console.pl
```

**Status**: [x] Completed

---

## High-Priority Improvements

### 5. Multi-Stage Dockerfile

**Current Problem**: Single-stage build includes build tools in final image, increasing size and attack surface.

**Solution**: Refactor to multi-stage build:
```dockerfile
# Stage 1: Build
FROM alpine:3.20 AS builder
RUN apk add gcc make perl-dev ...
RUN cd /spider/src && make

# Stage 2: Runtime
FROM alpine:3.20
COPY --from=builder /spider /spider
RUN apk add perl perl-modules-only ...
```

**Benefits**:
- Smaller final image
- No build tools in production
- Faster pulls and deployments

**Status**: [x] Completed

---

### 6. Add MariaDB Service

**Current Problem**: Database configuration exists but no database service is provided.

**Solution**: Add optional MariaDB service to docker-compose.yml:
```yaml
services:
  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: ${CLUSTER_DB_ROOT_PWD}
      MYSQL_DATABASE: ${CLUSTER_DB_NAME}
      MYSQL_USER: ${CLUSTER_DB_USER}
      MYSQL_PASSWORD: ${CLUSTER_DB_PASS}
    volumes:
      - mariadb_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 3

  dxspider:
    depends_on:
      mariadb:
        condition: service_healthy
    # ... rest of config
```

**Status**: [x] Completed (using Docker Compose profiles)

---

### 7. Improved Health Checks

**Current Problem**: Health check only verifies port is open, not that DXSpider is functional.

**Solution**: Create comprehensive health check script:
```bash
#!/bin/sh
# Check port is open
nc -z localhost ${CLUSTER_PORT} || exit 1
# Check cluster.pl is running
pgrep -f cluster.pl || exit 1
# Check ttyd is running
pgrep -f ttyd || exit 1
exit 0
```

**Status**: [x] Completed

---

### 8. Signal Handling & Graceful Shutdown

**Current Problem**: Container doesn't handle SIGTERM properly, may corrupt data on shutdown.

**Solution**: Add trap handlers to entrypoint.sh:
```bash
#!/bin/sh
cleanup() {
    echo "Shutting down DXSpider gracefully..."
    # Send shutdown command to cluster
    echo "shutdown" | nc localhost ${CLUSTER_PORT} 2>/dev/null
    # Wait for processes
    wait
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start services...
# Use exec for final command to receive signals
exec ttyd ...
```

**Status**: [x] Completed

---

### 9. Resource Limits

**Current Problem**: No resource constraints; container can consume unlimited CPU/memory.

**Solution**: Add to docker-compose.yml:
```yaml
services:
  dxspider:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 128M
```

**Status**: [x] Completed

---

### 10. Pin Base Image

**Current Problem**: `alpine:3.20` tag can change, breaking reproducibility.

**Solution**: Pin to specific digest:
```dockerfile
FROM alpine:3.20@sha256:<specific-hash>
```

Update periodically with security patches.

**Status**: [ ] Not Started

---

## Documentation Needs

### Required Files

| File | Purpose | Status |
|------|---------|--------|
| `LICENSE` | MIT license text (referenced in README) | [ ] Missing |
| `.env.example` | Configuration template | [x] Created |
| `CONTRIBUTING.md` | Contribution guidelines | [ ] Missing |
| `SECURITY.md` | Security policy & disclosure | [ ] Missing |
| `TROUBLESHOOTING.md` | Common issues & solutions | [ ] Missing |
| `.dockerignore` | Optimize Docker builds | [x] Created |

### README Improvements

- [ ] Fix claim about "multi-stage builds" (currently single-stage)
- [ ] Fix claim about "hardened configuration" (uses privileged mode)
- [ ] Add architecture diagram
- [ ] Add backup/restore procedures
- [ ] Document upgrade path
- [ ] Add multiple partner node examples

---

## Future Features

### Monitoring & Observability

#### Prometheus Metrics Endpoint
Export metrics for monitoring:
- `dxspider_spots_total` - Total spots received
- `dxspider_spots_per_minute` - Spot rate
- `dxspider_connected_users` - Current user count
- `dxspider_connected_nodes` - Partner node count
- `dxspider_node_latency_seconds` - Latency to partner nodes

#### Grafana Dashboard
Pre-built dashboard showing:
- Real-time spot activity
- User connections over time
- Geographic distribution of spots
- Band activity heatmap

---

### Web Dashboard UI

Modern web interface for DXSpider:
- Real-time spot display with filtering by band/mode/call
- Interactive map showing DX activity
- User management interface
- Node connection status
- Built with lightweight stack (Alpine.js + HTMX + Tailwind)

---

### Notification Integrations

#### Webhook Support
POST spot data to external URLs for integration with:
- Home automation systems
- Custom alerting
- Third-party logging

#### Discord Bot
- Channel notifications for specific DX
- Filter by DXCC entity, band, mode
- @mention for rare DX

#### Telegram Bot
- Similar to Discord integration
- Personal alerts via Telegram

---

### RBN (Reverse Beacon Network) Integration

Automatic integration with Reverse Beacon Network:
- Fetch CW/FT8/RTTY spots from RBN
- Configurable filtering (band, mode, SNR threshold)
- Merge with local spots
- Reduce duplicate spots

---

### Automatic TLS/SSL

Let's Encrypt integration:
- Auto-obtain certificates
- Auto-renewal via certbot
- Secure web console (HTTPS)
- Optional: stunnel for encrypted telnet

---

### Backup & Restore

Automated backup solution:
- Scheduled backups of user database
- Configuration backup
- Message archive backup
- One-command restore
- Optional S3/cloud storage upload

---

### CI/CD Pipeline

GitHub Actions workflow:
- Automated builds on push
- Multi-architecture images (amd64, arm64)
- Security scanning (Trivy, Snyk)
- Automated testing
- Docker Hub publishing
- Release tagging

---

### Kubernetes Support

Production-grade Kubernetes deployment:
- Helm chart for easy installation
- ConfigMaps for configuration
- Secrets management
- Horizontal Pod Autoscaling
- Persistent Volume Claims
- Ingress configuration
- High availability setup

---

## Implementation Priority

### Phase 1: Security & Stability (Critical)
1. [x] Remove privileged mode
2. [x] Add .gitignore and .env.example
3. [x] Fix file permissions
4. [x] Hide credentials from process list

### Phase 2: Best Practices (High)
5. [x] Multi-stage Dockerfile
6. [x] Add MariaDB service
7. [x] Improved health checks
8. [x] Signal handling
9. [x] Resource limits

### Phase 3: Documentation (Medium)
10. [ ] Add LICENSE file
11. [ ] Create CONTRIBUTING.md
12. [ ] Create SECURITY.md
13. [ ] Create TROUBLESHOOTING.md
14. [ ] Update README accuracy

### Phase 4: Features (Future)
15. [ ] Prometheus metrics
16. [ ] Web dashboard
17. [ ] Notification integrations
18. [ ] CI/CD pipeline
19. [ ] Kubernetes support

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help with these improvements.

## Security

See [SECURITY.md](SECURITY.md) for reporting security vulnerabilities.
