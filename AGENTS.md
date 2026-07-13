# AGENTS.md — Project Notes for Devin/AI Agents

## Project: 9M2PJU-DXSpider-Docker

Docker packaging of DXSpider (Perl-based DX Cluster software), using the `mojo` branch from EA3CV's fork.

### Key Facts

- **DXSpider branch**: `mojo` (active development fork by EA3CV)
- **Pinned commit SHA**: `3e9b3621d94dd45c68702e4a0f896aac33f2a91d`
- **Base image**: Alpine 3.23
- **Non-root user**: `sysop` (UID 1000, configurable via `SPIDER_UID`)
- **Compose profile for MariaDB**: `with-db` (NOT `db`)
- **Container capabilities**: `CHOWN, FOWNER, SETUID, SETGID` (cap_drop: ALL)
- **Default storage**: Flat-file (DB_File + SQLite); MariaDB optional
- **Ports**: 7300 (telnet), 8080 (web console/ttyd)
- **Placeholder callsign**: `9M2PJU-2` (node) / `9M2PJU` (sysop) — used in Dockerfile, entrypoint.sh, .env.example, README, and all docs. Historical references to Dirk Koopman (G1TLH) as DXSpider creator are preserved.

### Configuration Flow

1. User edits `.env` (copied from `.env.example`)
2. `docker-compose.yml` interpolates `.env` values into environment vars
3. `entrypoint.sh` reads env vars and generates:
   - `/spider/local/DXVars.pm` (from `DXVars.pm.issue` template)
   - `/spider/local/Listeners.pm`
4. Set `OVERWRITE_CONFIG=yes` in `.env` to force-regenerate config files

### Env Var Name Mapping

| `.env` name | Internal env var (entrypoint.sh) |
| :--- | :--- |
| `CLUSTER_DB_USER` | `CLUSTER_DBUSER` |
| `CLUSTER_DB_PASS` | `CLUSTER_DBPASS` |
| `CLUSTER_DB_HOSTNAME` + `CLUSTER_DB_NAME` + `CLUSTER_DB_PORT` | `CLUSTER_DSN` (composed in compose file) |

### Bind Mounts (all persistent on host)

| Host path | Container path | Purpose |
| :--- | :--- | :--- |
| `./local_data` | `/spider/local_data` | User DB, spots, logs, state (CRITICAL) |
| `./connect` | `/spider/connect` | Partner node connection scripts |
| `./local_cmd` | `/spider/local_cmd` | Crontab + local command overrides |
| `./startup` | `/spider/scripts/startup` | Boot-time commands |
| `./motd` | `/spider/local_data/motd` | MOTD (registered users) |
| `./motd_nor` | `/spider/local_data/motd_nor` | MOTD (non-registered) |
| `./cmd` | `/spider/cmd` | Custom user commands |
| `./msg` | `/spider/msg` | Bulletins and private messages |

### .gitignore Rules

- `.env` — never committed (contains secrets)
- `local_data/*` — runtime data, not in git (except `.gitkeep`)
- `connect/*`, `msg/*`, `local_cmd/*` — ignored except `.gitkeep` and `local_cmd/crontab`

### Documentation

Complete docs in `docs/` directory (10 files):
- `01-getting-started.md` — Installation & quick start
- `02-configuration.md` — All env vars and DXVars.pm
- `03-connecting-to-partners.md` — Inter-node links
- `04-filters.md` — Spot/announce filters
- `05-user-commands.md` — Full command reference
- `06-cron-and-automation.md` — Cron + startup
- `07-database-backend.md` — MariaDB setup
- `08-security.md` — Hardening guide
- `09-cloud-deployment.md` — AWS/GCP/Azure/VPS
- `10-troubleshooting.md` — FAQ and debugging

### Build & Run Commands

```bash
# Build and start (flat-file storage)
docker compose up -d --build

# Build and start with MariaDB
docker compose --profile with-db up -d --build

# View logs
docker compose logs -f dxspider

# Enter container shell
docker compose exec dxspider sh

# Access DXSpider console
docker compose exec dxspider /spider/perl/console.pl
```

### CI

- `.github/workflows/docker-publish.yml` — Multi-arch build (amd64, arm64, arm/v7, arm/v6) + smoke test (verifies port 7300 listens) + push to GHCR
- GHCR image: `ghcr.io/9m2pju/9m2pju-dxspider-docker:main` (auto-pushed on every merge to main)
- Verified working: both test and build jobs pass, image manifest confirms all 4 architectures

### Previous Work Completed

All fixes from prior sessions are committed:
- `.gitignore` and `.dockerignore` created
- `crontab` URLs fixed to use raw GitHub links
- `docker-compose.yml`: privileged removed, security caps, env vars fixed, MariaDB profile (`with-db`)
- `Dockerfile`: DXSpider pinned to SHA, `perl-dbd-sqlite` added, healthcheck improved, placeholder callsign 9M2PJU-2/9M2PJU
- `entrypoint.sh`: conditional DB config, signal handling, modernized `tr`, placeholder callsign 9M2PJU-2/9M2PJU
- `.env.example`: comprehensive rewrite with 9M2PJU placeholder
- `.env` and `local_data/` runtime files untracked from git
- CI smoke test added and verified passing
- README rewritten with "What is a DX Cluster?" intro, docs index table, beginner-friendly quick start
- Full `docs/` directory created (10 files) covering all aspects of the project
- Placeholder callsigns changed from GB7DJK/G1TLH to 9M2PJU-2/9M2PJU throughout (historical G1TLH references preserved)
- AGENTS.md created for future session reference
