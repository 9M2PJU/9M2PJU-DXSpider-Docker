# DXSpider Web Dashboard

A modern, lightweight web dashboard for DXSpider DX Cluster nodes. Provides real-time DX spot monitoring, node/user statistics, and an intuitive interface for amateur radio operators.

## Features

- **Real-time DX Spots**: Live feed of DX spots with auto-refresh
- **Band Filtering**: Quick filters for all amateur radio bands (160m-70cm)
- **Search**: Filter spots by callsign, spotter, or comment
- **Node Monitoring**: View connected DXSpider nodes
- **User Statistics**: Track connected users
- **Spot Analytics**: Visual charts of spot activity by band
- **Dark Theme**: Amateur radio-friendly dark interface
- **Responsive Design**: Works on desktop, tablet, and mobile
- **No Build Process**: Uses CDN-hosted libraries (Alpine.js, HTMX, Tailwind CSS)
- **Offline Capable**: No external API calls after initial load

## Technology Stack

- **Backend**: Mojolicious::Lite (Perl)
- **Frontend**: Alpine.js 3.x, HTMX 1.9.x, Tailwind CSS
- **Charts**: Chart.js
- **Container**: Alpine Linux 3.20

## Architecture

```
dashboard/
├── server/
│   └── dashboard.pl          # Mojolicious::Lite server
├── templates/
│   └── index.html.ep         # Main dashboard template
├── public/
│   ├── css/
│   │   └── styles.css        # Additional styles
│   └── js/
│       └── app.js            # Utility functions
├── docker-compose.dashboard.yml  # Docker Compose config
├── Dockerfile.dashboard      # Dashboard container image
└── README.md                 # This file
```

## Quick Start

### Method 1: Docker Compose (Recommended)

1. **Start DXSpider and Dashboard together**:

   ```bash
   cd /path/to/9M2PJU-DXSpider-Docker
   docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d
   ```

2. **Access the dashboard**:

   Open your browser to: http://localhost:8080

### Method 2: Standalone Container

1. **Build the dashboard image**:

   ```bash
   cd dashboard
   docker build -f Dockerfile.dashboard -t dxspider-dashboard .
   ```

2. **Run the container**:

   ```bash
   docker run -d \
     --name dxspider-dashboard \
     -p 8080:8080 \
     -v /path/to/local_data:/spider/local_data:ro \
     -e CLUSTER_CALLSIGN=9M2PJU-10 \
     -e CLUSTER_QTH="Kuala Lumpur, Malaysia" \
     dxspider-dashboard
   ```

### Method 3: Manual Perl Execution

1. **Install dependencies**:

   ```bash
   # Alpine/apk
   apk add perl perl-mojolicious perl-io-socket-ssl

   # Debian/Ubuntu
   apt-get install libmojolicious-perl

   # CPAN
   cpanm Mojolicious
   ```

2. **Run the dashboard**:

   ```bash
   cd dashboard/server
   export SPIDER_INSTALL_DIR=/path/to/spider
   perl dashboard.pl
   ```

3. **Access**: http://localhost:8080

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SPIDER_INSTALL_DIR` | `/spider` | Path to DXSpider installation |
| `DASHBOARD_PORT` | `8080` | Port for dashboard web interface |
| `DASHBOARD_MAX_SPOTS` | `100` | Maximum spots to return per API call |
| `CLUSTER_CALLSIGN` | `UNKNOWN` | Your cluster callsign |
| `CLUSTER_QTH` | `Unknown Location` | Your QTH/location |
| `CLUSTER_LOCATOR` | `` | Your Maidenhead locator |

### Customizing the Dashboard

#### Change Port

```bash
export DASHBOARD_PORT=9090
docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml up -d
```

#### Adjust Auto-Refresh Interval

Edit `/home/user/9M2PJU-DXSpider-Docker/dashboard/templates/index.html.ep`:

```javascript
// Change from 5000ms (5 seconds) to 10000ms (10 seconds)
this.refreshInterval = setInterval(() => {
    if (this.autoRefresh) {
        this.loadAll();
    }
}, 10000);
```

#### Add Custom Bands

Edit the `bands` array in `/home/user/9M2PJU-DXSpider-Docker/dashboard/templates/index.html.ep`:

```javascript
bands: ['160m', '80m', '40m', '30m', '20m', '17m', '15m', '12m', '10m', '6m', '2m', '70cm', '23cm'],
```

## API Endpoints

The dashboard provides RESTful JSON APIs:

### GET /api/spots

Get recent DX spots.

**Query Parameters**:
- `limit` (default: 50, max: 100) - Number of spots to return
- `band` (optional) - Filter by band (e.g., "20m")
- `search` (optional) - Search term for callsign/spotter/comment

**Response**:
```json
{
  "success": true,
  "count": 50,
  "spots": [
    {
      "frequency": 14195.0,
      "callsign": "VP8LP",
      "time": 1234567890,
      "comment": "Falkland Islands",
      "spotter": "9M2PJU",
      "origin": "9M2PJU-10",
      "band": "20m",
      "formatted_time": "14:30",
      "formatted_freq": "14195.0"
    }
  ]
}
```

### GET /api/spots/stream

Server-Sent Events stream for real-time spot updates.

**Response**: Text/event-stream with spot updates every 5 seconds.

### GET /api/nodes

Get connected DXSpider nodes.

**Response**:
```json
{
  "success": true,
  "count": 3,
  "nodes": [
    {
      "callsign": "GB7DXC",
      "connected": true,
      "type": "node",
      "sort": "Spider",
      "version": "1.55"
    }
  ]
}
```

### GET /api/users

Get connected users.

**Response**:
```json
{
  "success": true,
  "count": 12,
  "users": [
    {
      "callsign": "9M2PJU",
      "here": true
    }
  ]
}
```

### GET /api/stats

Get cluster statistics.

**Response**:
```json
{
  "success": true,
  "stats": {
    "spots_last_hour": 150,
    "connected_users": 12,
    "connected_nodes": 3,
    "band_distribution": {
      "20m": 45,
      "40m": 32,
      "15m": 28
    },
    "uptime_seconds": 86400,
    "cluster_callsign": "9M2PJU-10"
  }
}
```

### GET /api/health

Health check endpoint.

**Response**:
```json
{
  "status": "ok",
  "timestamp": 1234567890,
  "cluster": "9M2PJU-10"
}
```

## Performance & Caching

- **API Caching**: 5-second cache on all API endpoints to reduce DXSpider file I/O
- **Auto-Refresh**: Configurable auto-refresh interval (default: 5 seconds)
- **Resource Limits**: Dashboard container limited to 128MB RAM, 0.5 CPU
- **Lazy Loading**: Chart data loaded only when visible

## Security Considerations

1. **Read-Only Access**: Dashboard has read-only access to DXSpider data
2. **No Authentication**: Dashboard does not implement authentication (use reverse proxy)
3. **CORS Enabled**: For development; disable in production
4. **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection

### Adding Authentication (Recommended for Public Access)

Use a reverse proxy like Nginx with basic auth:

```nginx
server {
    listen 80;
    server_name dxcluster.example.com;

    location / {
        auth_basic "DXSpider Dashboard";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### Dashboard Won't Start

1. **Check DXSpider is running**:
   ```bash
   docker compose ps dxspider
   ```

2. **Check logs**:
   ```bash
   docker compose -f docker-compose.yml -f dashboard/docker-compose.dashboard.yml logs dashboard
   ```

3. **Verify port not in use**:
   ```bash
   netstat -tulpn | grep 8080
   ```

### No Spots Displayed

1. **Check DXSpider has spots**:
   ```bash
   docker compose exec dxspider sh
   cd /spider/perl
   ./console.pl
   # Type: show/dx 10
   ```

2. **Check API response**:
   ```bash
   curl http://localhost:8080/api/spots
   ```

3. **Check file permissions**:
   ```bash
   ls -la local_data/
   ```

### Slow Performance

1. **Increase cache TTL** in `/home/user/9M2PJU-DXSpider-Docker/dashboard/server/dashboard.pl`:
   ```perl
   my $CACHE_TTL = 10; # Increase from 5 to 10 seconds
   ```

2. **Reduce spot limit**:
   ```bash
   export DASHBOARD_MAX_SPOTS=50
   ```

3. **Disable auto-refresh**: Click "Auto-Refresh OFF" button in the UI

## Browser Compatibility

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Accessibility

- WCAG 2.1 AA compliant
- Keyboard navigation supported
- Screen reader compatible
- High contrast dark theme

## Future Enhancements

Potential features for future development:

- [ ] User authentication and sessions
- [ ] Customizable spot alerts (audio/visual)
- [ ] Spot filtering by DXCC entity
- [ ] Export spots to CSV/JSON
- [ ] Historical spot analysis
- [ ] Propagation prediction integration
- [ ] Mobile app (PWA)
- [ ] Multi-language support

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](/home/user/9M2PJU-DXSpider-Docker/CONTRIBUTING.md) in the main repository.

## License

This dashboard is part of the 9M2PJU-DXSpider-Docker project and is licensed under the same terms as DXSpider.

## Support

- **Documentation**: See main [README.md](/home/user/9M2PJU-DXSpider-Docker/README.md)
- **Issues**: GitHub Issues
- **DXSpider Docs**: http://www.dxcluster.org/

## Credits

- **DXSpider**: Created by Dirk Koopman (G1TLH)
- **Dashboard**: 9M2PJU
- **Technologies**: Mojolicious, Alpine.js, HTMX, Tailwind CSS, Chart.js

---

**73 de 9M2PJU**
