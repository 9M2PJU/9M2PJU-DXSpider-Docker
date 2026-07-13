# Troubleshooting

This guide covers common problems and their solutions. If you can't find your issue here, check the [DXSpider mailing list](https://mailman.tobit.co.uk/mailman/listinfo/dxspider-support) or open a GitHub issue.

---

## Quick Diagnostics

Run these first to narrow down any problem:

```bash
# Is the container running?
docker compose ps

# What do the logs say?
docker compose logs --tail 50 dxspider

# Is the healthcheck passing?
docker inspect dxspider --format '{{.State.Health.Status}}'

# Can you reach the telnet port?
telnet localhost 7300

# Can you reach the web console?
curl -I http://localhost:8080
```

---

## Container Won't Start

### Problem: Container exits immediately

**Symptoms**: `docker compose ps` shows the container as `Exited`.

**Diagnosis**:
```bash
docker compose logs dxspider
```

**Common causes & solutions**:

| Log Message | Cause | Solution |
| :--- | :--- | :--- |
| `permission denied` on bind mount | Host directory owned by wrong UID | `sudo chown -R 1000:1000 local_data/ local/ connect/ startup/ local_cmd/` |
| `DXVars.pm not found` | First-run config generation failed | Set `OVERWRITE_CONFIG=yes` in `.env`, restart |
| `Address already in use` | Port 7300 or 8080 is in use | Change `CLUSTER_PORT` or `CLUSTER_SYSOP_PORT` in `.env` |
| `cannot create user` | UID 1000 already exists in container | Set `SPIDER_UID` to a different value in `.env` |

### Problem: Container starts but is unhealthy

**Symptoms**: Container is `Up` but shows `(unhealthy)`.

**Diagnosis**:
```bash
# Check healthcheck logs
docker inspect --format '{{json .State.Health.Log}}' dxspider | jq

# Check if DXSpider is listening
docker compose exec dxspider sh -c 'netstat -tlnp 2>/dev/null || ss -tlnp'
```

**Solutions**:
- Wait 60 seconds — the healthcheck has a 30s start period.
- Check if DXVars.pm has valid values (callsign, locator, etc.).
- Set `OVERWRITE_CONFIG=yes` and restart to regenerate config.

---

## Connection Issues

### Problem: Can't connect via telnet

**Symptoms**: `telnet localhost 7300` fails or hangs.

**Diagnosis**:
```bash
# Check if port 7300 is listening
docker compose exec dxspider sh -c 'ss -tlnp | grep 7300'

# Check Docker port mapping
docker compose ps
```

**Solutions**:
- Verify `CLUSTER_PORT=7300` in `.env`.
- Verify `ports: - "7300:7300"` in `docker-compose.yml`.
- Check host firewall: `sudo ufw status` or `sudo iptables -L`.
- If running in the cloud, check the security group / firewall rules.

### Problem: Can connect locally but not remotely

**Symptoms**: `telnet localhost 7300` works, but `telnet your.public.ip 7300` doesn't.

**Solutions**:
- Open port 7300 in your cloud provider's firewall/security group.
- Open port 7300 in the host firewall:
  ```bash
  sudo ufw allow 7300/tcp
  ```
- If behind a router, forward port 7300 to your server.
- Check that Docker is binding to 0.0.0.0, not just localhost:
  ```yaml
  ports:
    - "0.0.0.0:7300:7300"  # or just "7300:7300"
  ```

### Problem: Web console shows blank page

**Symptoms**: Browser connects to port 8080 but shows nothing.

**Solutions**:
- Check that `WEB_USER` and `WEB_PASS` are set in `.env`.
- Try a different browser or clear cache.
- Check if ttyd is running:
  ```bash
  docker compose exec dxspider sh -c 'ps aux | grep ttyd'
  ```
- Check ttyd logs:
  ```bash
  docker compose logs dxspider | grep ttyd
  ```

---

## Partner Link Issues

### Problem: `connect <node>` does nothing

**Diagnosis**:
```bash
# Check if the connect script exists
ls -la connect/

# Check the script contents
cat connect/<node-callsign-lowercase>
```

**Solutions**:
- The filename must be **lowercase**: `connect/gb7mbc`, not `connect/GB7MBC`.
- The file must be readable: `chmod 644 connect/gb7mbc`.
- Verify the hostname and port in the connect script.
- Test the connection manually:
  ```bash
  docker compose exec dxspider sh -c 'telnet partner.hostname 7300'
  ```

### Problem: Partner link connects but drops immediately

**Diagnosis**:
```bash
docker compose logs dxspider | grep -i connect
```

**Solutions**:
- **Wrong password** — Verify the password in the connect script matches what the partner expects.
- **Partner hasn't authorized you** — Ask the partner sysop to add your callsign to their allowed list.
- **Partner node is down** — Try connecting to a different node.
- **Firewall blocking outbound** — Some cloud providers block outbound port 7300. Check your security group.

### Problem: Spots not propagating to/from partner

**Solutions**:
- Verify the partner is marked as a DXSpider node: `set/spider <call>`.
- Check hop counts: `show/hops <call>`. If hops are 0, spots won't propagate.
- Set hops if needed: `set/hops <call> spots 5`.
- Check filters: `show/filter` — a reject filter might be blocking spots.
- Check if the partner is in `badnode` list: `show/badnode`.

---

## Database Issues

### Problem: `Can't connect to MySQL server`

**Symptoms**: DXSpider logs show database connection errors.

**Solutions**:
- Verify the `db` container is running:
  ```bash
  docker compose --profile with-db ps
  ```
- Verify `CLUSTER_DB_HOSTNAME=db` in `.env`.
- Check MariaDB logs:
  ```bash
  docker compose --profile with-db logs db
  ```
- Verify credentials match between `.env` and the MariaDB service.
- If the volume is corrupted from a previous install, reset it:
  ```bash
  docker compose --profile with-db down
  docker volume rm 9m2pju-dxspider-docker_db_data
  docker compose --profile with-db up -d
  ```

### Problem: DXSpider still using flat-file despite DB config

**Solutions**:
- Set `OVERWRITE_CONFIG=yes` in `.env` and restart to regenerate `DXVars.pm`.
- Check that `CLUSTER_DB_HOSTNAME` is not empty in `.env`.
- Verify `DXVars.pm` has the DSN set:
  ```bash
  docker compose exec dxspider grep dsn /spider/local/DXVars.pm
  ```

---

## Performance Issues

### Problem: High CPU usage

**Solutions**:
- Check the number of connected users: `who`.
- Check for spot storms (excessive spots from a single source): `sh/dxstats`.
- Check for connection loops: `show/configuration` — if you see duplicate nodes, there may be a routing loop.
- Reduce debug logging: `unset/debug all` then `set/debug chan state`.
- Increase container resources if running on a very small VPS.

### Problem: High memory usage

**Solutions**:
- DXSpider caches spots in memory. For large nodes, this is normal.
- Check spot database size: `stat/db`.
- Restart the container to clear memory: `docker compose restart dxspider`.
- Consider using MariaDB backend to offload spot storage.

### Problem: Disk filling up

**Solutions**:
- Check log directory size:
  ```bash
  du -sh local_data/log/
  ```
- Clean old debug logs: `DXDebug::dbgclean()` (in crontab).
- Reduce log retention in DXVars.pm.
- Set Docker log rotation in `docker-compose.yml`:
  ```yaml
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"
  ```

---

## Configuration Issues

### Problem: Changes to `.env` not taking effect

**Solutions**:
- Set `OVERWRITE_CONFIG=yes` in `.env`, then:
  ```bash
  docker compose down
  docker compose pull
  docker compose up -d
  ```
- Set `OVERWRITE_CONFIG=no` afterward to preserve manual edits.
- Verify the env vars are reaching the container:
  ```bash
  docker compose exec dxspider env | grep CLUSTER_
  ```

### Problem: `DXVars.pm` has wrong values

**Solutions**:
- Regenerate with `OVERWRITE_CONFIG=yes`.
- Or edit manually:
  ```bash
  docker compose exec dxspider sh
  nano /spider/local/DXVars.pm
  exit
  docker compose restart dxspider
  ```

### Problem: Wrong grid square / QTH showing

**Solutions**:
- Check `CLUSTER_LOCATOR` and `CLUSTER_QTH` in `.env`.
- Regenerate config: `OVERWRITE_CONFIG=yes`, restart.
- Verify in DXVars.pm:
  ```bash
  docker compose exec dxspider grep -E 'mylocator|myqth' /spider/local/DXVars.pm
  ```

---

## User Issues

### Problem: Users can't post spots

**Solutions**:
- Check if `reqreg` is enabled: `show/var $main::reqreg`.
- If enabled, register the user: `set/register <call>`.
- Check if the user is in `badspotter` list: `show/badspotter`.
- Check if the user's IP is in `badip` list: `show/badip`.

### Problem: User can't log in

**Solutions**:
- Check if the callsign is locked out: `show/lockout`.
- If locked, unlock: `unset/lockout <call>`.
- Check if `passwdreq` is enabled and the user has no password.
- Check connection logs:
  ```bash
  docker compose logs dxspider | grep -i <call>
  ```

### Problem: User sees no spots

**Solutions**:
- Check user's filters: `show/filter` (as that user).
- Check if `set/dx` is enabled for the user.
- Check if the user has a reject filter blocking everything.

---

## Rebuilding from Scratch

If everything is broken and you want to start fresh:

> [!WARNING]
> This deletes all user data, spots, and configuration. Back up first!

```bash
# Stop everything
docker compose --profile with-db down

# Back up your config
cp .env .env.backup
cp -r connect/ connect.backup/

# Remove data volumes
docker volume rm 9m2pju-dxspider-docker_db_data 2>/dev/null

# Remove runtime data
rm -rf local_data/

# Pull fresh image and start
docker compose pull
docker compose up -d
```

---

## Getting Help

| Resource | URL |
| :--- | :--- |
| DXSpider Support Mailing List | https://mailman.tobit.co.uk/mailman/listinfo/dxspider-support |
| DXSpider Documentation | https://www.dxcluster.org/support/ |
| DXSpider GitHub (mojo branch) | https://github.com/EA3CV/dxspider |
| This Project's GitHub Issues | https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues |

When reporting an issue, include:
1. Your `.env` file (redact passwords).
2. The output of `docker compose logs --tail 100 dxspider`.
3. The output of `docker compose ps`.
4. The output of `docker version` and `docker compose version`.
5. What you expected to happen vs. what actually happened.
