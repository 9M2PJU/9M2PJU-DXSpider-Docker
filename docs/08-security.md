# Security

Running a public DX Cluster node exposes your server to the internet. This document covers security best practices, the protections built into this Docker image, and additional hardening you should apply.

---

## Built-In Protections

This Docker image includes several security features by default:

### Non-Root User

The DXSpider process runs as a non-root user (`sysop`, UID 1000) inside the container. Even if DXSpider is compromised, the attacker cannot gain root access to the container.

### No Privileged Mode

The container does **not** run in `--privileged` mode. It runs with a minimal set of Linux capabilities:

```yaml
cap_add:
  - CHOWN         # Change file ownership (for bind mounts)
  - SETUID        # Switch user (for the sysop user)
  - SETGID        # Switch group
  - FOWNER  # Override file ownership/perms (for bind mounts)
```

All other capabilities are dropped by default.

### Read-Only Filesystem Layers

The DXSpider installation (`/spider`) is built into the Docker image. Only the runtime data directories are writable via bind mounts. The base system libraries are immutable.

### Bad IP / Bad Word Lists

The default crontab fetches and loads several blocklists hourly:

| List | Purpose |
| :--- | :--- |
| `badip.torexit` | Tor exit nodes (often used for abuse) |
| `badip.torrelay` | Tor relay nodes |
| `badip.global` | Global IP blacklist |
| `baddx` | Banned DX callsigns |
| `badspotter` | Banned spotter callsigns |
| `badnode` | Banned node callsigns |
| `badword` | Banned words in spot text |

These protect your node from known abusers. You can add your own entries with `set/badip`, `set/baddx`, etc. (see [User Commands](05-user-commands.md)).

### Web Console Authentication

The web console (ttyd on port 8080) requires HTTP basic authentication. The username and password are set via `WEB_USER` and `WEB_PASS` in `.env`.

> [!IMPORTANT]
> **Change `WEB_PASS` from the default!** The default password is publicly known.

---

## Hardening Checklist

### 1. Change Default Passwords

```bash
# In .env:
WEB_PASS=<a-long-random-string>
CLUSTER_DB_PASS=<a-long-random-string>     # If using MariaDB
CLUSTER_DB_ROOT_PWD=<a-different-long-random-string>
```

Generate strong passwords:
```bash
openssl rand -base64 24
```

### 2. Use a Firewall

Only expose the ports you need:

| Port | Service | Expose Publicly? |
| :--- | :--- | :--- |
| 7300 | DX Cluster telnet | **Yes** (users need this) |
| 8080 | Web Console | **No** (sysop only - restrict to your IP or use SSH tunnel) |

Using `ufw` (Ubuntu/Debian):
```bash
sudo ufw default deny incoming
sudo ufw allow 7300/tcp       # DX Cluster
sudo ufw allow from YOUR.IP.ADDRESS to any port 8080  # Web console (your IP only)
sudo ufw enable
```

### 3. Restrict the Web Console with SSH Tunneling

Instead of exposing port 8080, access it through SSH:

1. Remove the `8080:8080` port mapping from `docker-compose.yml` (or bind it to localhost only):
   ```yaml
   ports:
     - "127.0.0.1:8080:8080"
   ```

2. Connect via SSH tunnel from your local machine:
   ```bash
   ssh -L 8080:localhost:8080 user@your-server-ip
   ```

3. Open `http://localhost:8080` in your browser.

### 4. Enable User Registration Requirement

Prevent anonymous users from posting spots or announcements:

In the `startup` file:
```
set/var $main::reqreg = 1
```

This requires the sysop to register each user with `set/register <call>` before they can post. Unregistered users have read-only access.

### 5. Require Passwords for Login

In the `startup` file:
```
set/var $main::passwdreq = 1
```

Then set passwords for each user:
```
set/password <call> <password>
```

### 6. Use Passwords on Partner Links

Always agree on a password with partner node sysops. In your connect script (`connect/<partner>`):

```bash
'login:' 'YOURCALL-2'
'pass' 'agreed-password'
```

### 7. Keep DXSpider Updated

To update to the latest DXSpider commit:

```bash
# Check for the latest commit at https://github.com/EA3CV/dxspider
# Then rebuild:
docker compose build --build-arg SPIDER_GIT_REF=<latest-sha>
docker compose up -d
```

### 8. Monitor Logs

Check logs regularly for suspicious activity:

```bash
docker compose logs --tail 100 dxspider
```

Look for:
- Repeated failed login attempts from the same IP
- Unusual spot patterns (many spots from one user in a short time)
- Connection attempts from unknown nodes

### 9. Set Hop Counts

Limit how far spots propagate to prevent loops and reduce network load:

```
set/hops gb7mbc spots 5
set/hops gb7mbc ann 5
```

### 10. Use Docker Network Isolation

If you're running other services on the same host, use a dedicated Docker network:

```yaml
networks:
  cluster_net:
    driver: bridge
```

This prevents the DXSpider container from accessing other containers' networks.

---

## Reporting Abuse

If you observe abuse from a connected user or node:

1. **Block the callsign**:
   ```
   set/badspotter BADCALL
   set/baddx BADCALL
   ```

2. **Block the IP**:
   ```
   set/badip 1.2.3.4
   ```

3. **Disconnect them**:
   ```
   disconnect BADCALL
   ```

4. **Lock them out**:
   ```
   set/lockout BADCALL
   ```

5. **Notify the network** - Send an announcement to other sysops:
   ```
   ann sysop Blocked BADCALL for abusive behavior
   ```

---

## Container Security Reference

| Setting | Value | Why |
| :--- | :--- | :--- |
| `privileged` | `false` (not set) | Container cannot access host devices |
| `user` | `sysop` (UID 1000) | Process runs as non-root |
| `cap_add` | CHOWN, SETUID, SETGID, FOWNER | Minimal capabilities for bind mounts |
| `read_only` | not set | Writable layers needed for runtime data |
| `security_opt` | `no-new-privileges:true` | Process cannot escalate privileges |
| Network | Default bridge | Isolated from host network |

To verify the running container's security settings:
```bash
docker inspect dxspider --format '{{.HostConfig.Privileged}} {{.HostConfig.CapAdd}}'
```

Expected output:
```
false [CHOWN SETUID SETGID FOWNER]
```
