# Getting Started

Welcome to 9M2PJU DXSpider Docker! This guide will walk you through everything you need to get your DX Cluster node up and running in minutes.

---

## What is a DX Cluster?

A DX Cluster is a network of servers that share real-time "spots" — reports of rare or interesting amateur radio stations heard on the air. When someone hears a DX station, they post a "spot" to their local cluster node, which then propagates it to all connected nodes worldwide within seconds.

**DXSpider** is the software that runs most of these cluster nodes. Originally created in the late 1990s and written in Perl, it has been actively maintained and extended by the amateur radio community for decades. This project packages DXSpider into a Docker container so you can deploy it without manually installing Perl, CPAN modules, or configuring a server.

---

## Prerequisites

Before you begin, you need:

1. **A computer running Linux, macOS, or FreeBSD**
   - **Linux**: Docker + Docker Compose (the installer can install Docker for you on Debian, Ubuntu, Fedora, CentOS, RHEL, Rocky, Alma, Alpine, Arch)
   - **macOS**: Docker Desktop (the installer can install it via Homebrew if missing)
   - **FreeBSD**: No Docker needed — the installer installs DXSpider natively via `pkg` + Perl modules
   - **Windows**: Install [Docker Desktop](https://docs.docker.com/desktop/windows/) with WSL2 enabled, then use the manual setup

2. **An amateur radio callsign** — You need a valid callsign to identify your node and yourself as sysop.

3. **Your Maidenhead grid square** — Used for distance/bearing calculations.
   - Find yours at: https://www.amsat.org/tools/grid-square-locator/

4. **A partner node to connect to** — To join the global DX Cluster network, you need another sysop to agree to link with you. See [Connecting to Partner Nodes](03-connecting-to-partners.md).

---

## Installation

### Option A: Quick Install (one command)

The installer detects your OS and does the right thing:
- **Linux**: installs Docker if missing, clones the repo, prompts for config, launches via `docker compose`
- **macOS**: installs Docker Desktop via Homebrew if missing, then uses `docker compose` (installs to `~/dxspider`)
- **FreeBSD**: installs DXSpider natively via `pkg` (no Docker), creates `rc.d` services, starts the cluster

```bash
curl -fsSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install.sh | bash
```

**Linux** — automatic Docker install: Debian, Ubuntu, Fedora, CentOS, RHEL, Rocky, Alma, Alpine, Arch. On other Linux distros, install Docker manually first, then re-run.

**macOS** — the installer installs Docker Desktop via Homebrew if needed. After the first install, open Docker Desktop from Applications, accept the license, wait for it to start, then re-run the script. Subsequent runs skip straight to `docker compose`.

**FreeBSD** — the installer automatically switches to the native path. All Perl dependencies come from FreeBSD `pkg` packages. The cluster runs as a native `rc.d` service (`service dxspider start|stop|restart`).

The installer installs to `/opt/dxspider` by default. Override with:
```bash
curl -fsSL https://raw.githubusercontent.com/9M2PJU/9M2PJU-DXSpider-Docker/main/install.sh | INSTALL_DIR=/home/me/dxspider bash
```

Skip to [Accessing Your Node](#accessing-your-node) after the installer finishes.

### Option B: Manual Setup

#### Step 1: Get the Code

```bash
git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
cd 9M2PJU-DXSpider-Docker
```

#### Step 2: Configure Your Node

Copy the example configuration and edit it:

```bash
cp .env.example .env
nano .env
```

At minimum, change these values:

```bash
CLUSTER_CALLSIGN=YOURCALL-2       # Your node's callsign (uppercase, SSID allowed)
CLUSTER_SYSOP_CALLSIGN=YOURCALL   # Your personal callsign
CLUSTER_SYSOP_NAME=Your Name      # Your name
CLUSTER_LOCATOR=YOURGRID          # Your Maidenhead grid square
CLUSTER_QTH="Your City, Country"  # Your location description
CLUSTER_SYSOP_EMAIL=you@email.com # Your email (for user registration)
WEB_USER=admin                    # Web console username
WEB_PASS=a-secure-password        # Web console password (CHANGE THIS!)
```

#### Step 3: Launch

```bash
docker compose pull      # Download the pre-built image from GHCR (fast)
docker compose up -d     # Start the cluster
```

This downloads the pre-built multi-arch image from GitHub Container Registry — no local compilation needed. It takes seconds, not minutes.

> **Prefer to build locally?** Use `docker compose up -d --build` instead. This compiles DXSpider and all Perl dependencies on your machine. The first build takes a few minutes; subsequent builds are faster thanks to Docker layer caching.

#### Step 4: Verify It's Running

Check the container status:

```bash
docker compose ps
```

You should see the container is `Up (healthy)`.

Check the logs:

```bash
docker compose logs -f
```

You should see:
```
Database backend disabled (CLUSTER_DB_HOSTNAME not set) — using flat-file storage.
(*) DXUser finished
Starting DXSpider Cluster...
Starting Web Console on port 8080...
```

---

## Accessing Your Node

### Telnet (Port 7300)

Connect from any DX Cluster client (or plain telnet):

```bash
telnet localhost 7300
```

You'll be prompted for your callsign:
```
login: YOURCALL
Hello YOURCALL, this is YOURCALL-2 in Your City, Country
running DXSpider V1.57 build 686
```

### Web Console (Port 8080)

Open a browser and go to:

```
http://localhost:8080
```

Enter the `WEB_USER` and `WEB_PASS` you set in `.env`. You'll get a web-based terminal connected to the DXSpider console — perfect for administration without SSH.

---

## Your First Commands

Once connected via telnet, try these:

| Command | What it does |
| :--- | :--- |
| `help` | Show available commands |
| `sh/dx` | Show recent DX spots |
| `sh/dx 20` | Show last 20 DX spots |
| `sh/dx 20m` | Show recent spots on the 20-meter band |
| `sh/configuration` | Show all connected nodes and users |
| `sh/wwv` | Show recent solar/geomagnetic reports |
| `set/name Your Name` | Set your name |
| `set/qth Your City` | Set your QTH |
| `set/location lat long` | Set your lat/lon |
| `set/homenode YOURCALL-2` | Set your home node |
| `bye` | Disconnect |

See the [User Commands Reference](05-user-commands.md) for the full list.

---

## Posting Your First DX Spot

When you hear a DX station on the air, you can share it with the world:

```
dx 14.195 ZL2ABC Strong signal on 20m CW
```

Format: `dx <frequency> <callsign> <comments>`

The spot will be propagated to all connected nodes within seconds.

> [!NOTE]
> If `reqreg` is enabled on the node (it is by default in this project), you must be registered before you can post spots. Contact the sysop (you!) to register your callsign from the console:
> ```
> set/register YOURCALL
> ```

---

## Stopping and Restarting

```bash
# Stop the cluster
docker compose down

# Start it again (no rebuild needed)
docker compose up -d

# Update to the latest pre-built image
docker compose pull
docker compose up -d

# Rebuild locally after custom modifications
docker compose up -d --build
```

Your data is safe — all user databases, spots, logs, and configuration are stored on the host filesystem, not inside the container. See [Persistence & Bind Mounts](../README.md#persistence--bind-mounts).

---

## Next Steps

- [Configuration Reference](02-configuration.md) — All environment variables explained
- [Connecting to Partner Nodes](03-connecting-to-partners.md) — Join the global network
- [Filters](04-filters.md) — Control what spots and announcements you see
- [Cron & Automation](06-cron-and-automation.md) — Schedule tasks and auto-reconnect
