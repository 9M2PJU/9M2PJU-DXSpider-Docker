# CLAUDE.md - AI Assistant Guide for 9M2PJU-DXSpider-Docker

## Project Overview

This repository provides a Docker-based deployment of **DXSpider**, a DX Cluster software used by amateur radio operators worldwide to share real-time DX (distant stations) spotting information. The project containerizes the DXSpider application created by Dirk Koopman (G1TLH), simplifying deployment and management.

### Purpose
- Enable amateur radio operators to run their own DX Cluster nodes
- Provide real-time DX spot sharing across a global network
- Support contesting and DX chasing activities

## Repository Structure

```
9M2PJU-DXSpider-Docker/
├── .env                    # Environment configuration (callsigns, ports, database)
├── Dockerfile              # Container build instructions (Alpine Linux based)
├── docker-compose.yml      # Service orchestration configuration
├── entrypoint.sh           # Container startup script (generates config, starts services)
├── startup                 # DXSpider startup commands (partner connections)
├── crontab                 # Scheduled tasks for DXSpider
├── motd                    # Message of the Day displayed to connecting users
├── cmd/                    # DXSpider command scripts (Perl)
│   ├── *.pl               # Root-level commands (dx.pl, connect.pl, etc.)
│   ├── Aliases            # Command alias definitions
│   ├── accept/            # Accept filter commands
│   ├── clear/             # Clear commands
│   ├── create/            # User/resource creation commands
│   ├── delete/            # Deletion commands
│   ├── forward/           # Message forwarding commands
│   ├── get/               # Data retrieval commands
│   ├── load/              # Configuration loading commands
│   ├── reject/            # Reject filter commands
│   ├── set/               # Configuration setting commands
│   ├── show/              # Display commands
│   ├── stat/              # Statistics commands
│   └── unset/             # Unset configuration commands
├── connect/                # Node connection scripts
│   └── <callsign>         # Telnet connection definitions for partner nodes
├── local_cmd/              # Local custom commands (mounted volume)
├── local_data/             # Runtime data storage (logs, cache, user database)
│   ├── users.v3j          # User database
│   ├── dupefile           # Duplicate spot detection cache
│   ├── log/               # Application logs
│   └── debug/             # Debug logs
└── msg/                    # Message system configuration
    ├── forward.pl.issue   # Message forwarding rules template
    ├── badmsg.pl.issue    # Bad message filtering template
    └── swop.pl.issue      # Message swap rules template
```

## Technology Stack

- **Base Image**: Alpine Linux 3.20
- **Language**: Perl (DXSpider core)
- **Web Terminal**: ttyd (browser-based console access)
- **Database**: MariaDB/MySQL (optional, for persistent storage)
- **DXSpider Branch**: `mojo` (default) or `master`

## Key Configuration Files

### `.env` - Environment Variables
Primary configuration file containing:
- `CLUSTER_CALLSIGN` - Node callsign (e.g., 9M2PJU-10)
- `CLUSTER_DXSPIDER_BRANCH` - DXSpider version (mojo/master)
- `CLUSTER_SYSOP_*` - Sysop details (name, callsign, email)
- `CLUSTER_LATITUDE/LONGITUDE/LOCATOR/QTH` - Geographic location
- `CLUSTER_PORT` - Telnet port (default: 7300)
- `CLUSTER_SYSOP_PORT` - Web console port (default: 8050)
- `CLUSTER_DB_*` - Database connection settings

### `entrypoint.sh` - Container Initialization
- Generates `Listeners.pm` for network configuration
- Creates `DXVars.pm` from environment variables
- Handles callsign uppercase conversion
- Cleans stale lock files
- Starts DXSpider cluster and ttyd web console

### `startup` - DXSpider Startup Script
Commands executed when DXSpider starts:
- Load forwarding configuration
- Set partner nodes as spider type
- Initiate connections to partner nodes

### `crontab` - Scheduled Tasks
DXSpider internal cron format for:
- Automatic reconnection to partner nodes
- Periodic maintenance tasks

### `connect/<callsign>` - Partner Node Definitions
Connection scripts for linking to other DX Cluster nodes:
```
timeout 15
connect telnet <hostname> <port>
'login:' '<callsign>'
```

## Development Workflow

### Building and Running

```bash
# Initial setup
nano .env                    # Configure environment variables
nano startup                 # Configure startup commands
nano crontab                 # Configure scheduled tasks

# Create partner node connections
touch connect/<partner-callsign>
nano connect/<partner-callsign>

# Build and start
docker compose up -d --build

# View logs
docker compose logs -f

# Restart after changes
docker compose down && docker compose up -d --build
```

### Adding Partner Node Connections

1. Create connection file: `connect/<callsign-lowercase>`
2. Add connection details:
   ```
   timeout 15
   connect telnet <hostname> <port>
   'login:' '<your-callsign>'
   ```
3. Update `crontab` for auto-reconnection:
   ```
   0,5,10,20,30,40,50 * * * * start_connect('<callsign>') unless connected('<callsign>')
   ```
4. Update `startup` to connect on boot:
   ```
   load/forward
   set/spider <callsign>
   connect <callsign>
   ```

### Modifying Commands

Commands are Perl scripts in `cmd/` directory. Structure:
- Receive `$self` (connection object) and `$line` (user input)
- Return array: `(status_code, @output_lines)`
- Use `$self->msg('key')` for localized messages
- Check privileges with `$self->priv`

## Important Conventions

### Callsign Handling
- All callsigns are stored and compared in **UPPERCASE**
- SSIDs (e.g., -10) are appended to base callsigns
- Use `basecall()` to strip SSIDs for comparison

### Privilege Levels
Commands check user privilege levels:
- Level 0: Basic user
- Level 5+: Sysop/admin commands
- Check with: `return (1, $self->msg('e5')) if $self->priv < 5;`

### Registration Requirement
- `$self->isregistered` check required for spot submission
- Unregistered users cannot post DX spots (anti-spam measure)

### Error Message Codes
Common error codes in Perl commands:
- `e5` - Permission denied (insufficient privilege)
- `e6` - Missing required argument
- `dx1` - Invalid frequency
- `dx2` - Insufficient DX command arguments
- `dx3` - Invalid frequency/callsign format

## Docker Volumes

The following paths are mounted for persistence:
- `./startup:/spider/scripts/startup` - Startup commands
- `./crontab:/spider/local_cmd/crontab` - Cron jobs
- `./connect:/spider/connect` - Node connections
- `./motd:/spider/local_data/motd` - Message of the day
- `./local_data:/spider/local_data` - Runtime data
- `./cmd:/spider/cmd` - Command scripts
- `./msg:/spider/msg` - Message configuration

## Network Ports

- **7300** (configurable): Telnet port for DX Cluster clients
- **8050** (configurable): Web console (ttyd) for sysop access

## Testing Changes

1. Make configuration changes
2. Rebuild container: `docker compose up -d --build`
3. Check logs: `docker compose logs -f`
4. Connect via telnet: `telnet localhost 7300`
5. Access web console: `http://localhost:8050`

## Common Tasks for AI Assistants

### When Asked to Add a New Partner Node
1. Create `connect/<callsign>` file with connection details
2. Add crontab entry for auto-reconnection
3. Update startup script to connect on boot

### When Asked to Modify MOTD
Edit the `motd` file with new welcome message content.

### When Asked to Change Configuration
Edit `.env` file and rebuild the container.

### When Debugging Connection Issues
1. Check `local_data/log/` for DXSpider logs
2. Verify network connectivity to partner nodes
3. Check `local_data/cluster.lck` for stale locks
4. Review entrypoint.sh for configuration generation issues

## External Resources

- DXSpider Documentation: http://www.dxcluster.org/
- DXSpider Git Repository: git://scm.dxcluster.org/scm/spider
- Project GitHub: https://github.com/9M2PJU/9M2PJU-DXSpider-Docker
