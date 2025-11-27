<div align="center">

# 9M2PJU-DXSpider-Docker

### Containerized DX Cluster for Amateur Radio

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![DXSpider](https://img.shields.io/badge/DXSpider-FF4B4B?style=for-the-badge&logo=radio&logoColor=white)](http://www.dxcluster.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/9M2PJU/9M2PJU-DXSpider-Docker?style=for-the-badge)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/stargazers)

*Deploy your own DX Cluster node in minutes*

[Features](#-features) | [Quick Start](#-quick-start) | [Configuration](#%EF%B8%8F-configuration) | [Documentation](#-documentation) | [Contributing](#-contributing)

</div>

---

## Acknowledgment

This project containerizes **DXSpider**, created by **Dirk Koopman (G1TLH)**. We extend our gratitude for his pioneering work that transformed DX Cluster networking and continues to empower the global amateur radio community.

- DXSpider Project: http://www.dxcluster.org/
- DXSpider Repository: git://scm.dxcluster.org/scm/spider

---

## Overview

9M2PJU-DXSpider-Docker provides a production-ready, containerized deployment of DXSpider. It eliminates complex setup procedures while providing security hardening and operational best practices.

### Why Use This?

- **5-Minute Setup** - Clone, configure, run
- **Security Hardened** - Non-root container, no privileged mode, resource limits
- **Production Ready** - Health checks, graceful shutdown, logging
- **Multi-Architecture** - Supports amd64 and arm64

---

## Features

### Container Architecture

- **Multi-stage Docker build** - Smaller images, no build tools in production
- **Non-privileged execution** - Runs as UID 1000, no root access
- **Resource limits** - CPU and memory constraints prevent runaway containers
- **Health monitoring** - Automatic health checks detect failures

### Operational Features

- **Signal handling** - Graceful shutdown on SIGTERM/SIGINT
- **Auto-reconnect** - Crontab-based partner node reconnection
- **Web console** - Browser-based sysop access via ttyd
- **Optional database** - MariaDB support via Docker Compose profiles

---

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
cd 9M2PJU-DXSpider-Docker

# Create configuration from template
cp .env.example .env

# Edit configuration (set your callsign, location, etc.)
nano .env

# Start the cluster
docker compose up -d --build

# Verify it's running
docker compose ps
docker compose logs -f
```

### Test Connection

```bash
# Telnet to your cluster
telnet localhost 7300

# Or access web console
# Open http://localhost:8050 in browser
```

---

## Configuration

### Environment Variables (.env)

Copy `.env.example` to `.env` and customize:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLUSTER_CALLSIGN` | Your node callsign | `9M2PJU-10` |
| `CLUSTER_SYSOP_CALLSIGN` | Sysop callsign | `9M2PJU` |
| `CLUSTER_SYSOP_NAME` | Sysop name | `Piju` |
| `CLUSTER_QTH` | Location description | `Kuala Lumpur, Malaysia` |
| `CLUSTER_LOCATOR` | Maidenhead grid | `OJ03UD` |
| `CLUSTER_LATITUDE` | Latitude (decimal) | `+3.14` |
| `CLUSTER_LONGITUDE` | Longitude (decimal) | `+101.69` |
| `CLUSTER_PORT` | Telnet port | `7300` |
| `CLUSTER_SYSOP_PORT` | Web console port | `8050` |

### Adding Partner Nodes

1. **Create connection script**:
   ```bash
   nano connect/partner-call
   ```

   Content:
   ```
   timeout 15
   connect telnet partner.example.com 7300
   'login:' 'YOURCALL-10'
   ```

2. **Add to startup**:
   ```bash
   # Edit startup file
   nano startup
   ```

   Add:
   ```
   load/forward
   set/spider PARTNER-CALL
   connect PARTNER-CALL
   ```

3. **Add auto-reconnect crontab**:
   ```bash
   nano crontab
   ```

   Add:
   ```
   0,10,20,30,40,50 * * * * start_connect('PARTNER-CALL') unless connected('PARTNER-CALL')
   ```

4. **Restart**:
   ```bash
   docker compose restart dxspider
   ```

### Using MariaDB (Optional)

For persistent database storage:

```bash
# Start with database profile
docker compose --profile database up -d --build

# Configure database in .env
CLUSTER_DB_NAME=dxspider
CLUSTER_DB_HOSTNAME=mariadb
CLUSTER_DB_PORT=3306
CLUSTER_DB_USER=sysop
CLUSTER_DB_PASS=your_secure_password
```

### Full Stack Deployment (Phase 4 Features)

Deploy DXSpider with **all features** including dashboard and metrics monitoring using the unified configuration:

#### Features Included:
- **Web Dashboard** - Modern web interface for viewing spots, nodes, and statistics (port 8080)
- **Prometheus** - Metrics collection and time-series database (port 9090)
- **Grafana** - Metrics visualization with pre-built dashboards (port 3000)

#### Quick Deploy (All Features):

```bash
# 1. Configure environment variables
cp .env.example .env
nano .env

# IMPORTANT: Set these required variables in .env:
#   DASHBOARD_PORT=8080
#   DASHBOARD_CORS_ORIGIN=              # Leave empty for security
#   GF_ADMIN_PASSWORD=your_strong_password   # REQUIRED for Grafana
#   CLUSTER_METRICS_PORT=9100

# 2. Deploy all services
docker compose -f docker-compose.full.yml --profile all up -d --build

# 3. Access services:
#   DXSpider Telnet:    telnet localhost 7300
#   Web Console (ttyd): http://localhost:8050
#   Dashboard:          http://localhost:8080
#   Prometheus:         http://localhost:9090
#   Grafana:            http://localhost:3000
```

#### Selective Deployment:

Deploy only specific features using profiles:

```bash
# Base DXSpider only (no optional features)
docker compose -f docker-compose.full.yml up -d

# DXSpider + Dashboard only
docker compose -f docker-compose.full.yml --profile dashboard up -d

# DXSpider + Metrics only (Prometheus + Grafana)
docker compose -f docker-compose.full.yml --profile metrics up -d

# DXSpider + Database + Dashboard
docker compose -f docker-compose.full.yml --profile database --profile dashboard up -d

# All features
docker compose -f docker-compose.full.yml --profile all up -d
```

#### Dashboard Configuration

The web dashboard provides real-time spot monitoring with filtering and search:

```bash
# Environment variables in .env:
DASHBOARD_PORT=8080                    # Dashboard web port
DASHBOARD_MAX_SPOTS=100               # Max spots to display
DASHBOARD_CORS_ORIGIN=                # Leave empty (disabled by default)
                                      # Only set if using reverse proxy
```

**Security Note**: CORS is disabled by default. Only set `DASHBOARD_CORS_ORIGIN` if you're using a reverse proxy and understand the security implications.

#### Metrics Configuration

Grafana requires explicit password configuration for security:

```bash
# REQUIRED in .env:
GF_ADMIN_PASSWORD=your_strong_password_here

# Optional:
GF_ADMIN_USER=admin                   # Default: admin
CLUSTER_METRICS_PORT=9100            # Prometheus metrics port
```

**First-time Grafana access**:
1. Navigate to `http://localhost:3000`
2. Login with username `admin` and the password you set in `.env`
3. Pre-configured dashboards are automatically loaded

#### Alternative: Modular Deployment

You can also deploy features separately using individual compose files:

```bash
# Base DXSpider
docker compose up -d

# Add dashboard (from project root)
docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d

# Add metrics (from project root)
docker compose -f docker-compose.yml -f metrics/docker-compose.metrics.yml up -d
```

**Note**: The unified `docker-compose.full.yml` is recommended for easier management.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Host                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  dxspider-net                         │  │
│  │                                                       │  │
│  │  ┌─────────────────┐      ┌─────────────────────┐    │  │
│  │  │    DXSpider     │      │  MariaDB (optional) │    │  │
│  │  │                 │      │                     │    │  │
│  │  │  ┌───────────┐  │      │  ┌───────────────┐  │    │  │
│  │  │  │cluster.pl │  │◄────►│  │  dxspider DB  │  │    │  │
│  │  │  └───────────┘  │      │  └───────────────┘  │    │  │
│  │  │  ┌───────────┐  │      │                     │    │  │
│  │  │  │   ttyd    │  │      └─────────────────────┘    │  │
│  │  │  └───────────┘  │                                 │  │
│  │  └────────┬────────┘                                 │  │
│  │           │                                          │  │
│  └───────────┼──────────────────────────────────────────┘  │
│              │                                              │
│    ┌─────────┴─────────┐                                   │
│    │                   │                                   │
│    ▼                   ▼                                   │
│  :7300              :8050                                  │
│  Telnet           Web Console                              │
└─────────────────────────────────────────────────────────────┘
         │                   │
         ▼                   ▼
    DX Clients          Browser
   (N1MM, etc.)        (Sysop)
```

---

## Operations

### Viewing Logs

```bash
# All logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100
```

### Restarting

```bash
docker compose restart dxspider
```

### Updating

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose down
docker compose up -d --build
```

### Backup

```bash
# Backup user database
cp ./local_data/users.v3j ./backup/users.v3j.$(date +%Y%m%d)

# Backup configuration
cp .env ./backup/env.$(date +%Y%m%d)
tar -czf ./backup/config-$(date +%Y%m%d).tar.gz startup crontab connect/
```

### Restore

```bash
# Restore user database
cp ./backup/users.v3j.YYYYMMDD ./local_data/users.v3j

# Restart to apply
docker compose restart dxspider
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI assistant guide for this codebase |
| [ROADMAP.md](ROADMAP.md) | Project roadmap and planned features |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security policy and reporting |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |

---

## Supported Clients

Any telnet-capable DX client works:

- N1MM Logger+
- DXTelnet
- CC Cluster
- Log4OM
- DX Lab Suite
- Logger32
- Standard telnet clients

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## Support

- **Issues**: [GitHub Issues](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Security**: [SECURITY.md](SECURITY.md)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Note: This license applies to the Docker configuration. DXSpider itself is a separate project by G1TLH with its own licensing.

---

<div align="center">

**73 de 9M2PJU**

*Made for the Amateur Radio Community*

</div>
