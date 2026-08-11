# Configuration Reference

This document covers every configuration option available in 9M2PJU DXSpider Docker.

---

## Environment Variables (`.env`)

All configuration is done through the `.env` file (copy from `.env.example`). These values are read by `docker-compose.yml` and passed to the container's `entrypoint.sh`, which generates the DXSpider configuration files.

### Cluster Identity

| Variable | Required | Default | Description |
| :--- | :--- | :--- | :--- |
| `CLUSTER_CALLSIGN` | **Yes** | `N0CALL-2` | The callsign of your DX Cluster node. Use uppercase. An SSID is allowed (e.g., `-2` for a cluster node). |
| `CLUSTER_SYSOP_CALLSIGN` | **Yes** | `9M2PJU` | Your personal amateur radio callsign (the admin/sysop). Uppercase. |
| `CLUSTER_SYSOP_NAME` | No | `DXSpider Sysop` | Your display name, shown in cluster info. |
| `CLUSTER_QTH` | No | `DXSpider Node` | Human-readable location description (e.g., "Kuala Lumpur, Malaysia"). |

### Location

| Variable | Required | Default | Description |
| :--- | :--- | :--- | :--- |
| `CLUSTER_LOCATOR` | Recommended | `JO01aa` | Your Maidenhead grid square (uppercase). Used for distance/bearing calculations. Find yours at https://www.amsat.org/tools/grid-square-locator/ |
| `CLUSTER_LATITUDE` | No | `0` | Latitude in decimal degrees. `+` = North, `-` = South. Example: `+03.08` |
| `CLUSTER_LONGITUDE` | No | `0` | Longitude in decimal degrees. `+` = East, `-` = West. Example: `+101.41` |

### Sysop Contact

| Variable | Required | Default | Description |
| :--- | :--- | :--- | :--- |
| `CLUSTER_SYSOP_EMAIL` | No | `9m2pju@hamradio.my` | Email where users can contact you for registration/support. |
| `CLUSTER_SYSOP_BBS_ADDRESS` | No | `bbs@localhost` | BBS forwarding address for message routing. Leave as default if unsure. |

### Network Ports

| Variable | Default | Description |
| :--- | :--- | :--- |
| `CLUSTER_PORT` | `7300` | Telnet port for user connections. Users connect here with telnet or a DX Cluster client. |
| `CLUSTER_SYSOP_PORT` | `8080` | Web Console port (ttyd). Access via browser for sysop administration. |

> [!IMPORTANT]
> If you change `CLUSTER_PORT`, make sure to open the new port in your firewall and update any port forwarding on your router.

### Web Console

| Variable | Default | Description |
| :--- | :--- | :--- |
| `WEB_USER` | `sysop` | Username for the web console (HTTP basic auth). |
| `WEB_PASS` | `changeme-web` | Password for the web console. **Change this from the default!** |

### Optional MariaDB Backend

By default, DXSpider uses flat-file storage (DB_File + SQLite). This is sufficient for most nodes. To enable MariaDB for spot logging, see [Database Backend](07-database-backend.md).

| Variable | Default | Description |
| :--- | :--- | :--- |
| `CLUSTER_DB_HOSTNAME` | *(empty)* | Database hostname. Set to `db` to use the compose service. Leave empty for flat-file storage. |
| `CLUSTER_DB_NAME` | `spider` | Database name. |
| `CLUSTER_DB_USER` | `sysop` | Database username. |
| `CLUSTER_DB_PASS` | `sysoppassword` | Database password. |
| `CLUSTER_DB_PORT` | `3306` | Database port. |
| `CLUSTER_DB_ROOT_PWD` | `changeme-root` | MariaDB root password (compose `db` service only). |

### Build & Advanced

| Variable | Default | Description |
| :--- | :--- | :--- |
| `CLUSTER_DXSPIDER_BRANCH` | `mojo` | DXSpider git branch. `mojo` (recommended, active development) or `master`. |
| `SPIDER_GIT_REF` | *(pinned SHA)* | Pin DXSpider to a specific commit SHA for reproducible builds. Override to upgrade. |
| `SPIDER_UID` | `1000` | UID for the sysop user inside the container. Match your host UID for hassle-free bind mounts. |
| `OVERWRITE_CONFIG` | `no` | Set to `yes` to force-regenerate `DXVars.pm` and `Listeners.pm` on every start. |

---

## How Configuration Works

9M2PJU DXSpider Docker uses a two-layer configuration system:

### Layer 1: Environment Variables (`.env`)

You edit `.env` on the host. Docker Compose reads it and passes the values to the container as environment variables.

### Layer 2: Generated Config Files (`entrypoint.sh`)

The `entrypoint.sh` script reads the environment variables and generates two DXSpider configuration files:

1. **`/spider/local/Listeners.pm`** - Tells DXSpider which address and port to listen on:
   ```perl
   package main;
   use vars qw(@listen);
   @listen = (
       ["0.0.0.0", 7300],
   );
   1;
   ```

2. **`/spider/local/DXVars.pm`** - The main DXSpider configuration file, generated from the upstream template (`DXVars.pm.issue`) by substituting your env values into the Perl variables:
   ```perl
   $mycall = "N0CALL-2";
   $myalias = "9M2PJU";
   $myname = "Piju";
   $myqth = "Kuala Lumpur, Malaysia";
   $mylocator = "OJ03UD";
   $mylatitude = "+03.08";
   $mylongitude = "+101.41";
   $myemail = "9m2pju\@hamradio.my";
   ```

### When Are Config Files Regenerated?

- **First start**: Both files are generated from your `.env` values.
- **Subsequent starts**: Files are NOT regenerated (your manual edits are preserved).
- **Force regeneration**: Set `OVERWRITE_CONFIG=yes` in `.env` and restart. This overwrites both files with values from `.env`. Set it back to `no` afterward.

---

## DXVars.pm - Full Variable Reference

The following variables are set by `entrypoint.sh` from your `.env` file. For advanced users who want to edit `DXVars.pm` directly (inside the container or by bind-mounting `./local`), here's what each does:

| Perl Variable | Env Source | Purpose |
| :--- | :--- | :--- |
| `$mycall` | `CLUSTER_CALLSIGN` | The cluster node's callsign (uppercase) |
| `$myalias` | `CLUSTER_SYSOP_CALLSIGN` | The sysop's personal callsign |
| `$myname` | `CLUSTER_SYSOP_NAME` | Sysop's display name |
| `$myqth` | `CLUSTER_QTH` | QTH description |
| `$mylocator` | `CLUSTER_LOCATOR` | Maidenhead grid square |
| `$mylatitude` | `CLUSTER_LATITUDE` | Latitude (decimal degrees) |
| `$mylongitude` | `CLUSTER_LONGITUDE` | Longitude (decimal degrees) |
| `$myemail` | `CLUSTER_SYSOP_EMAIL` | Sysop email |
| `$mybbsaddr` | `CLUSTER_SYSOP_BBS_ADDRESS` | BBS forwarding address |
| `$dsn` | `CLUSTER_DSN` | Database DSN (only if DB enabled) |
| `$dbuser` | `CLUSTER_DBUSER` | Database username (only if DB enabled) |
| `$dbpass` | `CLUSTER_DBPASS` | Database password (only if DB enabled) |

### Additional DXVars.pm Variables (not set by .env)

These variables exist in the upstream `DXVars.pm.issue` template but are not exposed via `.env`. To change them, edit `DXVars.pm` directly inside the container or bind-mount `./local`:

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `@my_cc` | *(auto)* | Country codes your node is located in. Auto-detected from `$mycall` if left empty. |
| `@debug` | `qw(chan connect cron msg progress state badword)` | Debug channels to log. |
| `$do_xml` | `0` | Enable XML output. |
| `$id` | - | Telegram Bot ID (for Telegram integration, EA3CV fork feature). |
| `$token` | - | Telegram Bot token. |
| `$email_enable` | `1` | Enable email SMTP for registration queries. |
| `$email_from` | - | SMTP "from" address. |
| `$email_smtp` | - | SMTP server hostname. |
| `$email_port` | `587` | SMTP port (587 for STARTTLS, 465 for SSL). |
| `$email_user` | - | SMTP username. |
| `$email_pass` | - | SMTP password. |

---

## Changing Configuration After First Start

If you change values in `.env` and want them applied:

### Option A: Force Regenerate (Recommended)

```bash
# In .env, set:
OVERWRITE_CONFIG=yes

# Then restart:
docker compose down
docker compose pull
docker compose up -d

# After verifying, set it back:
# OVERWRITE_CONFIG=no
```

### Option B: Edit DXVars.pm Directly

```bash
# Enter the container
docker compose exec dxspider sh

# Edit the config
nano /spider/local/DXVars.pm

# Restart the cluster
exit
docker compose restart
```

### Option C: Bind-Mount the local Directory

For permanent manual control over `DXVars.pm` and `Listeners.pm`, add this to `docker-compose.yml`:

```yaml
volumes:
  - ./local:/spider/local:rw
```

Then create `./local/DXVars.pm` on the host and edit it directly. Set `OVERWRITE_CONFIG=no` to prevent the entrypoint from overwriting your file.

---

## Multi-Architecture Build Configuration

The Dockerfile accepts these build arguments (passed via `docker-compose.yml` or `docker build --build-arg`):

| Build Arg | Default | Purpose |
| :--- | :--- | :--- |
| `SPIDER_INSTALL_DIR` | `/spider` | Installation directory inside the container. |
| `SPIDER_USERNAME` | `sysop` | Username for the non-root user. |
| `SPIDER_UID` | `1000` | UID for the non-root user. |
| `SPIDER_VERSION` | `mojo` | DXSpider git branch (`mojo` or `master`). |
| `SPIDER_GIT_REF` | `3e9b3621...` | Pinned commit SHA for reproducible builds. |

To build with a different DXSpider version:

```bash
docker compose build --build-arg SPIDER_VERSION=master
```

To upgrade DXSpider to a newer commit:

```bash
# Find the latest commit SHA from https://github.com/EA3CV/dxspider
docker compose build --build-arg SPIDER_GIT_REF=<new-sha>
docker compose up -d
```
