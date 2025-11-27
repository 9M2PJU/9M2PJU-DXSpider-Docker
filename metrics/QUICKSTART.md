# DXSpider Metrics - Quick Start Guide

This guide will get you up and running with DXSpider metrics monitoring in 5 minutes.

## Prerequisites

- Docker and Docker Compose installed
- DXSpider container configured and ready

## Step 1: Start the Metrics Stack

```bash
# Navigate to project directory
cd /path/to/9M2PJU-DXSpider-Docker

# Start DXSpider with Prometheus and Grafana
docker compose -f docker-compose.yml -f metrics/docker-compose.metrics.yml up -d --build
```

## Step 2: Verify Services

Wait 30-60 seconds for all services to start, then check:

```bash
# Check container status
docker compose ps

# You should see:
# - dxspider (running)
# - dxspider-prometheus (running)
# - dxspider-grafana (running)
```

## Step 3: Test Endpoints

```bash
# Test metrics endpoint (should return Prometheus text format)
curl http://localhost:9100/metrics

# Test health endpoint (should return JSON)
curl http://localhost:9100/health

# Test Prometheus (should return HTML)
curl http://localhost:9090

# Test Grafana (should return HTML)
curl http://localhost:3000
```

## Step 4: Access Grafana Dashboard

1. Open browser to **http://localhost:3000**
2. Login with:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted (or skip)
4. Navigate to: **Dashboards** → **Browse** → **DXSpider** → **DXSpider Cluster Monitoring**

## Step 5: Verify Metrics

You should see:

- ✅ Connected users count
- ✅ Connected nodes count
- ✅ Spots per minute
- ✅ Uptime
- ✅ Graphs updating in real-time

## Stopping the Stack

```bash
# Stop all services
docker compose -f docker-compose.yml -f metrics/docker-compose.metrics.yml down

# Stop and remove volumes (WARNING: deletes all metrics data)
docker compose -f docker-compose.yml -f metrics/docker-compose.metrics.yml down -v
```

## Troubleshooting

### No metrics appearing in Grafana

**Check Prometheus targets:**
1. Go to http://localhost:9090/targets
2. Verify `dxspider` target shows "UP" status
3. If "DOWN", check logs: `docker compose logs dxspider`

### Grafana shows "No Data"

**Check time range:**
- Dashboard default is "Last 1 hour"
- Try "Last 5 minutes" to see recent data
- Ensure DXSpider has been running long enough to generate metrics

### Port conflicts

**If ports 3000, 9090, or 9100 are already in use:**

Edit `metrics/docker-compose.metrics.yml` and change:

```yaml
prometheus:
  ports:
    - "9091:9090"  # Changed from 9090:9090

grafana:
  ports:
    - "3001:3000"  # Changed from 3000:3000
```

Also update `.env`:
```bash
CLUSTER_METRICS_PORT=9101  # Changed from 9100
```

### Container fails to start

**Check logs:**
```bash
docker compose logs dxspider
docker compose logs prometheus
docker compose logs grafana
```

**Common issues:**
- Insufficient memory (increase Docker resources)
- Permission errors (run: `sudo chown -R 1000:1000 metrics/`)
- Missing files (re-download repository)

## What's Next?

- **Customize Dashboard**: Edit panels in Grafana UI
- **Add Alerts**: Set up Grafana alerting for critical metrics
- **Export Metrics**: Configure remote Prometheus scraping
- **Advanced Monitoring**: Enable Node Exporter for system metrics

See [README.md](README.md) for full documentation.

## Quick Reference

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | N/A |
| Metrics | http://localhost:9100/metrics | N/A |
| DXSpider Telnet | localhost:7300 | N/A |
| DXSpider Web | http://localhost:8050 | sysop/password |

## Support

- **Full Documentation**: [README.md](README.md)
- **Project Issues**: GitHub Issues
- **DXSpider Docs**: http://www.dxcluster.org/
