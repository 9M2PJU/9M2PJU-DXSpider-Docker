# DXSpider Dashboard - Quick Start Guide

Get your dashboard running in under 2 minutes!

## Prerequisites

- Docker and Docker Compose installed
- DXSpider container running (or will be auto-started)

## Installation Steps

### 1. Navigate to the Project Directory

```bash
cd /home/user/9M2PJU-DXSpider-Docker
```

### 2. Start the Dashboard

**Option A: Using the startup script (Easiest)**

```bash
cd dashboard
./start.sh
```

**Option B: Using Docker Compose directly**

```bash
docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d
```

### 3. Access the Dashboard

Open your browser to: **http://localhost:8080**

That's it! You should see your DXSpider dashboard with live spots.

## Common Commands

```bash
# View dashboard logs
cd dashboard && ./start.sh --logs

# Stop dashboard
cd dashboard && ./start.sh --stop

# Rebuild dashboard
cd dashboard && ./start.sh --build

# Restart dashboard
docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml restart dashboard
```

## Customization

### Change the Port

Edit `/home/user/9M2PJU-DXSpider-Docker/.env`:

```bash
DASHBOARD_PORT=9090
```

Then restart:

```bash
docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml restart dashboard
```

### Adjust Refresh Rate

Edit `/home/user/9M2PJU-DXSpider-Docker/dashboard/templates/index.html.ep` and change:

```javascript
this.refreshInterval = setInterval(() => {
    if (this.autoRefresh) {
        this.loadAll();
    }
}, 5000);  // Change 5000 to desired milliseconds
```

## Dashboard Features

- **Real-time Spots**: Auto-refreshing every 5 seconds
- **Band Filters**: Click any band button to filter spots
- **Search**: Type callsign/spotter name to search
- **Statistics**: View connected users, nodes, and spot rates
- **Charts**: Visual representation of spot activity by band

## Toggle Auto-Refresh

Click the "Auto-Refresh ON/OFF" button in the top right of the spot feed to pause/resume automatic updates.

## Troubleshooting

### "Cannot connect" or blank page

1. Check if dashboard is running:
   ```bash
   docker compose ps dashboard
   ```

2. Check logs:
   ```bash
   docker compose logs dashboard
   ```

3. Verify DXSpider is running:
   ```bash
   docker compose ps dxspider
   ```

### No spots showing

1. Verify DXSpider has spots:
   ```bash
   docker compose exec dxspider sh -c "cd /spider/perl && echo 'show/dx 10' | ./console.pl"
   ```

2. Check API directly:
   ```bash
   curl http://localhost:8080/api/spots
   ```

## API Endpoints

Test the API endpoints:

```bash
# Get recent spots
curl http://localhost:8080/api/spots

# Get 20m spots only
curl http://localhost:8080/api/spots?band=20m

# Search for specific callsign
curl http://localhost:8080/api/spots?search=VP8

# Get connected nodes
curl http://localhost:8080/api/nodes

# Get statistics
curl http://localhost:8080/api/stats

# Health check
curl http://localhost:8080/api/health
```

## Next Steps

- Read the full [Dashboard README](README.md) for advanced features
- Review [API Documentation](README.md#api-endpoints)
- Explore customization options
- Set up authentication for public access

## Support

For issues or questions:
1. Check the [Troubleshooting section](README.md#troubleshooting) in README
2. Review Docker logs
3. Open an issue on GitHub

---

**73 and happy DXing!**
