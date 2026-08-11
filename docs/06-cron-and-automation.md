# Cron & Automation

DXSpider has a built-in cron scheduler that runs tasks on a schedule. Combined with the startup file, you can automate connections, list updates, and maintenance tasks.

---

## The Startup File

The `startup` file (on your host) contains DXSpider commands that run **once** when the cluster starts. It's bind-mounted into the container at `/spider/scripts/startup`.

### Location

```
./startup                    # On the host
/spider/scripts/startup      # Inside the container
```

### Example

```bash
# Load message forwarding configuration
load/forward

# Mark partner as a DXSpider node and connect
set/spider gb7mbc
connect gb7mbc

# Allow inbound internet connections
set/var $Internet::allow = 1

# Require users to register before posting spots
set/var $main::reqreg = 1

# Set the contest DX cluster host
set/var $Internet::contest_host = "contest.dxtron.com"
```

### Editing

Edit the file on your host, then restart:
```bash
docker compose restart dxspider
```

---

## The Cron Schedule

The crontab file (on your host) contains scheduled tasks. It's bind-mounted into the container at `/spider/local_cmd/crontab`.

### Location

```
./local_cmd/crontab          # On the host
/spider/local_cmd/crontab    # Inside the container
```

### Format

Standard cron format:
```
minute hour day-of-month month day-of-week  command
```

| Field | Values |
| :--- | :--- |
| minute | 0-59 |
| hour | 0-23 |
| day-of-month | 1-31 |
| month | 1-12 |
| day-of-week | 0-7 (0 and 7 = Sunday) |

Use `*` for "every", and comma-separated lists (e.g., `0,10,20,30,40,50`).

> [!IMPORTANT]
> Commands are **Perl expressions**, not shell commands. Use the functions described below.

### Available Cron Functions

| Function | Description |
| :--- | :--- |
| `run_cmd('command')` | Run a DXSpider console command |
| `spawn('shell command')` | Spawn an external shell process |
| `start_connect('nodename')` | Start a connection to a node |
| `connected('nodename')` | Returns true if the node is currently connected |
| `DXUser::export('filename')` | Export the user database |
| `DXDebug::dbgclean()` | Clean old debug log files |
| `Spot::daily()` | Run daily spot maintenance |

### Example Crontab Entries

```bash
# --- Partner node reconnection ---
# Reconnect to GB7MBC every 10 minutes if the link has dropped
0,10,20,30,40,50 * * * * start_connect('gb7mbc') unless connected('gb7mbc')

# --- Bad IP / bad word list updates ---
# Fetch updated lists from EA3CV's repo every hour
30 * * * * spawn('cd /spider/local_data; wget -qN https://raw.githubusercontent.com/EA3CV/dxspider_info/main/download/badip.global')
32 * * * * run_cmd('load/badip')

# --- Maintenance ---
# Export user database weekly (Wednesday at 00:01)
1 0 * * 3 DXUser::export("$main::data/user_asc")

# Clean debug logs daily at 00:05
5 0 * * * DXDebug::dbgclean()

# Run daily spot maintenance at 03:00
0 3 * * * Spot::daily()

# --- Custom commands ---
# Show a station count every hour
0 * * * * run_cmd("sh/station all")
```

### Editing

Edit the file on your host, then restart:
```bash
docker compose restart dxspider
```

The change takes effect on the next restart.

---

## Default Cron Entries

This project ships with default cron entries that:

1. **Fetch bad-IP lists** hourly from EA3CV's repository:
   - `badip.torexit` - Known Tor exit nodes
   - `badip.torrelay` - Known Tor relay nodes
   - `badip.global` - Global IP blacklist

2. **Fetch bad-DX/spotter/node/word lists** hourly:
   - `baddx` - Banned DX callsigns
   - `badspotter` - Banned spotter callsigns
   - `badnode` - Banned node callsigns
   - `badword` - Banned words in spot text

3. **Load the updated lists** into DXSpider 2 minutes after download.

These protect your node from known abusers and are fetched using `raw.githubusercontent.com` (not the HTML `github.com/.../blob/...` URLs, which would download HTML instead of data).

---

## Per-User Startup Scripts

Each user can have their own startup script that runs when they log in:

```
set/startup                   # Create your startup script (interactive)
unset/startup                 # Remove your startup script
sh/startup                    # View your startup script
```

As sysop, you can set startup scripts for other users:
```
set/startup <call>            # Create a startup script for <call>
unset/startup <call>          # Remove it
sh/startup <call>             # View it
```

---

## Automation Examples

### Auto-Reconnect to Multiple Partners

In `local_cmd/crontab`:
```bash
0,10,20,30,40,50 * * * * start_connect('gb7mbc') unless connected('gb7mbc')
0,10,20,30,40,50 * * * * start_connect('w3lpl') unless connected('w3lpl')
0,10,20,30,40,50 * * * * start_connect('k1ttt') unless connected('k1ttt')
```

### Daily User Database Backup

In `local_cmd/crontab`:
```bash
# Backup user database daily at 02:00
0 2 * * * DXUser::export("$main::data/user_asc")
0 2 * * * spawn('cp /spider/local_data/users.v3j /spider/local_data/users.v3j.bak')
```

### Periodic Announcements

In `local_cmd/crontab`:
```bash
# Daily welcome announcement at 09:00
0 9 * * * run_cmd('ann Welcome to the cluster! Good DX.')
```

### RBN Feed Connection

In `local_cmd/crontab`:
```bash
# Connect to RBN every 5 minutes if not connected
*/5 * * * * start_connect('rbn') unless connected('rbn')
```

---

## Using `set/var` for Runtime Configuration

You can set DXSpider internal variables at startup or via cron:

In the `startup` file:
```
set/var $Internet::allow = 1
set/var $main::reqreg = 1
set/var $Internet::contest_host = "contest.dxtron.com"
```

Common variables:

| Variable | Effect |
| :--- | :--- |
| `$main::reqreg = 1` | Require registration to post spots |
| `$main::passwdreq = 1` | Require password for login |
| `$Internet::allow = 1` | Allow inbound internet connections |
| `$Internet::contest_host = "host"` | Set contest cluster host |
