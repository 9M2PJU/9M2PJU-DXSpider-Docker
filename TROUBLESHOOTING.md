# Troubleshooting Guide

This guide helps diagnose and fix common issues with 9M2PJU-DXSpider-Docker.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Container Issues](#container-issues)
- [Connection Problems](#connection-problems)
- [Configuration Errors](#configuration-errors)
- [Database Issues](#database-issues)
- [Performance Problems](#performance-problems)
- [Partner Node Issues](#partner-node-issues)
- [Web Console Issues](#web-console-issues)
- [Log Analysis](#log-analysis)
- [Recovery Procedures](#recovery-procedures)

---

## Quick Diagnostics

Run these commands first to assess the situation:

```bash
# Check container status
docker compose ps

# View recent logs
docker compose logs --tail=50

# Check container health
docker inspect --format='{{.State.Health.Status}}' $(docker compose ps -q dxspider)

# Check resource usage
docker stats --no-stream

# Test telnet port
nc -zv localhost 7300

# Test web console port
nc -zv localhost 8050
```

---

## Container Issues

### Container Won't Start

**Symptoms**: Container exits immediately or keeps restarting

**Check logs**:
```bash
docker compose logs dxspider
```

**Common causes**:

#### 1. Port Already in Use
```
Error: bind: address already in use
```

**Fix**:
```bash
# Find what's using the port
sudo lsof -i :7300
sudo lsof -i :8050

# Either stop the conflicting service or change ports in .env
CLUSTER_PORT=7301
CLUSTER_SYSOP_PORT=8051
```

#### 2. Missing .env File
```
ERROR: Missing required environment variables
```

**Fix**:
```bash
cp .env.example .env
nano .env  # Configure your settings
```

#### 3. Permission Denied
```
Permission denied: /spider/local_data
```

**Fix**:
```bash
# Fix ownership of mounted volumes
sudo chown -R 1000:1000 ./local_data
sudo chown -R 1000:1000 ./connect
sudo chown -R 1000:1000 ./cmd
```

#### 4. Lock File Exists
```
cluster.lck exists - another cluster running?
```

**Fix**:
```bash
# Remove stale lock file
rm -f ./local_data/cluster.lck

# Restart container
docker compose restart dxspider
```

### Container Unhealthy

**Symptoms**: `docker compose ps` shows "unhealthy"

**Diagnose**:
```bash
# Check health check details
docker inspect --format='{{json .State.Health}}' $(docker compose ps -q dxspider) | jq

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' $(docker compose ps -q dxspider)
```

**Common causes**:
- DXSpider cluster.pl crashed
- Port not responding
- Process started but not ready

**Fix**:
```bash
# Restart the container
docker compose restart dxspider

# If persistent, rebuild
docker compose down
docker compose up -d --build
```

### Out of Memory

**Symptoms**: Container killed, "OOMKilled" in logs

**Check**:
```bash
docker inspect --format='{{.State.OOMKilled}}' $(docker compose ps -q dxspider)
```

**Fix**: Increase memory limit in docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      memory: 1G  # Increase from 512M
```

---

## Connection Problems

### Can't Connect via Telnet

**Test connection**:
```bash
telnet localhost 7300
```

#### Connection Refused

**Causes**:
1. Container not running
2. DXSpider not started
3. Wrong port

**Fix**:
```bash
# Verify container is running
docker compose ps

# Check if port is listening inside container
docker compose exec dxspider nc -zv localhost 7300

# Verify port mapping
docker compose port dxspider 7300
```

#### Connection Timeout

**Causes**:
1. Firewall blocking
2. Network issues
3. Wrong IP address

**Fix**:
```bash
# Check firewall (Ubuntu/Debian)
sudo ufw status
sudo ufw allow 7300/tcp

# Check firewall (RHEL/CentOS)
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=7300/tcp --permanent
sudo firewall-cmd --reload

# Test from another machine
telnet YOUR_SERVER_IP 7300
```

### Connection Drops Immediately

**Symptoms**: Connect succeeds but disconnects right away

**Causes**:
1. Invalid callsign in .env
2. DXSpider configuration error

**Check logs**:
```bash
docker compose logs --tail=100 dxspider | grep -i error
```

**Fix**: Verify .env settings:
```bash
# Callsign must be valid format
CLUSTER_CALLSIGN=9M2PJU-10  # Valid
CLUSTER_CALLSIGN=invalid    # Invalid
```

---

## Configuration Errors

### Environment Variables Not Applied

**Symptoms**: Changes to .env don't take effect

**Fix**:
```bash
# Must rebuild after .env changes
docker compose down
docker compose up -d --build
```

### Callsign Not Uppercase

**Symptoms**: Callsign appears lowercase in cluster

**Note**: The entrypoint automatically converts to uppercase. If still lowercase:

```bash
# Force config regeneration
docker compose down
rm -f ./local_data/DXVars.pm
docker compose up -d
```

### OVERWRITE_CONFIG Not Working

**Symptoms**: Config changes not applied on restart

**Fix**: Set environment variable:
```bash
# In docker-compose.yml or .env
OVERWRITE_CONFIG=yes
```

Or manually:
```bash
docker compose down
rm -f ./local_data/Listeners.pm
rm -f ./local_data/DXVars.pm
docker compose up -d
```

---

## Database Issues

### MariaDB Connection Failed

**Symptoms**: Database errors in logs when using `--profile database`

**Check MariaDB status**:
```bash
docker compose --profile database ps
docker compose --profile database logs mariadb
```

#### Database Not Ready

```
Can't connect to MySQL server
```

**Fix**: Wait for MariaDB to initialize (can take 30-60 seconds on first run)

```bash
# Check if MariaDB is healthy
docker compose --profile database ps

# View initialization progress
docker compose --profile database logs -f mariadb
```

#### Authentication Failed

```
Access denied for user 'sysop'
```

**Fix**: Verify credentials match:
```bash
# In .env, these must match
CLUSTER_DB_USER=sysop
CLUSTER_DB_PASS=your_password

# These are used by MariaDB
CLUSTER_DB_ROOT_PWD=root_password
```

### Database Corrupted

**Fix**:
```bash
# Stop services
docker compose --profile database down

# Remove database volume (WARNING: loses all data)
docker volume rm 9m2pju-dxspider-docker_mariadb_data

# Restart fresh
docker compose --profile database up -d
```

---

## Performance Problems

### High CPU Usage

**Diagnose**:
```bash
docker stats
docker compose exec dxspider top
```

**Common causes**:
1. Too many connected users
2. Excessive spot traffic
3. Runaway process

**Fix**:
```bash
# Restart container
docker compose restart dxspider

# If persistent, check for issues
docker compose logs --tail=200 dxspider
```

### High Memory Usage

**Diagnose**:
```bash
docker stats --format "table {{.Container}}\t{{.MemUsage}}"
```

**Fix**: Increase limits or investigate:
```bash
# Check what's using memory inside container
docker compose exec dxspider ps aux --sort=-%mem | head -10
```

### Slow Response Times

**Causes**:
1. Network latency to partner nodes
2. Disk I/O issues
3. Resource contention

**Fix**:
```bash
# Check disk I/O
docker compose exec dxspider iostat

# Check network
docker compose exec dxspider ping -c 3 partner-node.example.com
```

---

## Partner Node Issues

### Can't Connect to Partner Node

**Check connection script**:
```bash
cat ./connect/partner-callsign
```

**Expected format**:
```
timeout 15
connect telnet hostname.example.com 7300
'login:' 'YOURCALL-10'
```

**Debug connection**:
```bash
# Test from inside container
docker compose exec dxspider nc -zv hostname.example.com 7300

# Test from host
telnet hostname.example.com 7300
```

### Partner Connection Keeps Dropping

**Causes**:
1. Network instability
2. Partner node restarting
3. Authentication issues

**Fix**: Check crontab for auto-reconnect:
```bash
cat ./crontab
```

Should contain:
```
0,5,10,20,30,40,50 * * * * start_connect('partner-call') unless connected('partner-call')
```

### Partner Not Recognized as Spider Node

**Symptoms**: Spots not flowing correctly

**Fix**: Set node type in startup:
```bash
# Edit startup file
echo "set/spider PARTNER-CALL" >> ./startup

# Restart
docker compose restart dxspider
```

---

## Web Console Issues

### Can't Access Web Console

**Test**:
```bash
curl -I http://localhost:8050
```

#### Connection Refused

**Fix**:
```bash
# Check if ttyd is running
docker compose exec dxspider pgrep -a ttyd

# Check port binding
docker compose port dxspider 8050
```

#### Authentication Failed

**Fix**: Verify credentials in .env:
```bash
# These are used for web console auth
CLUSTER_DB_USER=sysop
CLUSTER_DB_PASS=your_password
```

### Web Console Shows Blank Screen

**Causes**:
1. JavaScript blocked
2. WebSocket connection failed
3. Browser incompatibility

**Fix**:
- Try different browser
- Check browser console for errors (F12)
- Ensure WebSocket connections allowed through proxy

### Console Disconnects Frequently

**Causes**:
1. Network instability
2. Proxy timeout
3. Container restarting

**Fix**: If using reverse proxy, increase timeouts:
```nginx
proxy_read_timeout 3600;
proxy_send_timeout 3600;
```

---

## Log Analysis

### Viewing Logs

```bash
# All logs
docker compose logs

# Recent logs
docker compose logs --tail=100

# Follow logs in real-time
docker compose logs -f

# Specific service
docker compose logs dxspider

# With timestamps
docker compose logs -t
```

### Common Log Messages

#### Normal Operation
```
[entrypoint] DXSpider cluster started successfully
[entrypoint] ttyd started
[entrypoint] DXSpider is ready!
```

#### Warning Signs
```
# Connection issues
unable to connect to partner-node

# Resource issues
Out of memory

# Authentication
Access denied
```

### DXSpider Internal Logs

```bash
# View cluster logs
ls -la ./local_data/log/

# Recent log
tail -100 ./local_data/log/cluster.log

# Debug logs
ls -la ./local_data/debug/
```

---

## Recovery Procedures

### Full Reset (Keeps Data)

```bash
# Stop everything
docker compose down

# Remove containers and networks
docker compose down --remove-orphans

# Rebuild and start
docker compose up -d --build
```

### Full Reset (Fresh Start)

```bash
# Stop everything
docker compose down -v

# Remove local data (WARNING: loses all data)
rm -rf ./local_data/*
touch ./local_data/.placeholder

# Remove generated configs
rm -f ./local_data/DXVars.pm
rm -f ./local_data/Listeners.pm

# Rebuild
docker compose up -d --build
```

### Backup Before Reset

```bash
# Backup user database
cp ./local_data/users.v3j ./users.v3j.backup

# Backup logs
tar -czf logs-backup.tar.gz ./local_data/log/

# Backup configuration
cp .env .env.backup
cp ./startup ./startup.backup
cp ./crontab ./crontab.backup
```

### Restore from Backup

```bash
# Restore user database
cp ./users.v3j.backup ./local_data/users.v3j

# Restore configuration
cp .env.backup .env

# Restart
docker compose up -d --build
```

---

## Getting More Help

If these steps don't resolve your issue:

1. **Check existing issues**: [GitHub Issues](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues)

2. **Gather information**:
   ```bash
   # System info
   uname -a
   docker --version
   docker compose version

   # Container info
   docker compose ps
   docker compose logs --tail=200 > logs.txt
   ```

3. **Open a new issue** with:
   - Description of the problem
   - Steps to reproduce
   - Relevant logs
   - Your environment details

4. **For DXSpider-specific issues**, consult:
   - DXSpider documentation: http://www.dxcluster.org/
   - DXSpider mailing list

---

73 de 9M2PJU
