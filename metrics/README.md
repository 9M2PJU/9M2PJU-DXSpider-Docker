# DXSpider Prometheus Metrics Monitoring

This directory contains a complete Prometheus metrics monitoring solution for DXSpider, including:

- **Prometheus metrics exporter** - Perl/Mojolicious HTTP server exposing DXSpider metrics
- **Prometheus** - Time-series database for metrics collection
- **Grafana** - Visualization and dashboarding platform
- **Pre-built dashboards** - Ready-to-use DXSpider monitoring dashboards

## Architecture

```
┌─────────────┐         ┌──────────────┐         ┌──────────┐
│  DXSpider   │────────▶│  Prometheus  │────────▶│ Grafana  │
│   :9100     │ scrape  │    :9090     │  query  │  :3000   │
│             │         │              │         │          │
│ metrics_    │         │ Time-series  │         │Dashboard │
│ server.pl   │         │   Database   │         │          │
└─────────────┘         └──────────────┘         └──────────┘
```

## Quick Start

### 1. Start DXSpider with Metrics

```bash
# Start DXSpider with metrics monitoring stack
docker compose -f docker-compose.yml -f metrics/docker-compose.metrics.yml up -d --build

# View logs
docker compose logs -f
```

### 2. Access the Dashboards

- **Grafana Dashboard**: http://localhost:3000
  - Default credentials: `admin` / `admin`
  - Change password on first login

- **Prometheus UI**: http://localhost:9090

- **Raw Metrics Endpoint**: http://localhost:9100/metrics

### 3. View DXSpider Dashboard

1. Open Grafana at http://localhost:3000
2. Login with default credentials
3. Navigate to **Dashboards** → **DXSpider Cluster Monitoring**
4. The dashboard will automatically populate with metrics

## Metrics Exported

The metrics server exposes the following metrics in Prometheus format:

### Information Metrics

```prometheus
# Node information with version and callsign labels
dxspider_info{version="1.55",callsign="9M2PJU-10"} 1

# Uptime in seconds
dxspider_uptime_seconds 86400
```

### Connection Metrics

```prometheus
# Connected users (local)
dxspider_users_connected 5

# Total users in cluster network
dxspider_cluster_users_total 150

# Connected nodes by type
dxspider_nodes_connected{type="spider"} 3
dxspider_nodes_connected{type="clx"} 1
dxspider_nodes_connected{type="ar_cluster"} 2

# Total nodes in cluster
dxspider_cluster_nodes_total 25
```

### Spot Metrics

```prometheus
# Total spots by band (counter)
dxspider_spots_total{band="20m"} 1234
dxspider_spots_total{band="40m"} 567
dxspider_spots_total{band="15m"} 890

# Spots in the last minute (gauge)
dxspider_spots_per_minute 12
```

### Traffic Metrics

```prometheus
# Network traffic counters
dxspider_bytes_in_total 12345678
dxspider_bytes_out_total 23456789
```

### Process Metrics

```prometheus
# Process start time (Unix timestamp)
dxspider_process_start_time_seconds 1701234567
```

## Dashboard Panels

The included Grafana dashboard provides:

1. **Overview Stats** - Connected users, nodes, spots/min, uptime
2. **Spot Rate Graph** - DX spots per minute by band over time
3. **Band Distribution** - Pie chart showing spot distribution by band
4. **User Connections** - Graph of local and total cluster users
5. **Node Types** - Connected nodes by software type
6. **Network Traffic** - Bytes in/out over time
7. **Node Summary Table** - Detailed breakdown of connected nodes

## Configuration

### Environment Variables

Configure in `.env` file:

```bash
# Metrics server port (default: 9100)
CLUSTER_METRICS_PORT=9100

# Grafana admin credentials
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=your_secure_password
```

### Prometheus Configuration

Edit `metrics/prometheus/prometheus.yml` to customize:

- **Scrape interval**: How often to collect metrics (default: 15s)
- **Retention**: How long to keep metrics (default: 30 days)
- **Additional targets**: Add more exporters

### Grafana Configuration

- **Datasources**: `metrics/grafana/provisioning/datasources/`
- **Dashboards**: `metrics/grafana/provisioning/dashboards/`
- **Dashboard JSON**: `metrics/grafana/dashboards/dxspider.json`

## Metrics Server Details

### Implementation

The metrics server is implemented in Perl using **Mojolicious::Lite**:

- **File**: `metrics/prometheus/metrics_server.pl`
- **Port**: 9100 (configurable via `CLUSTER_METRICS_PORT`)
- **Framework**: Mojolicious::Lite (already installed in DXSpider container)
- **Performance**: Non-blocking I/O, 5-second metric caching to reduce load

### Endpoints

- `GET /` - Server information
- `GET /metrics` - Prometheus metrics (text format)
- `GET /health` - Health check endpoint (JSON)

### Starting Manually

If you need to start the metrics server independently:

```bash
# Inside DXSpider container
cd /spider/metrics
perl metrics_server.pl daemon -l http://*:9100
```

## Customization

### Adding Custom Metrics

Edit `metrics/prometheus/metrics_server.pl` to add custom metrics:

```perl
# Add new metric in get_all_metrics() function
push @metrics, sprintf(
    '# HELP dxspider_custom_metric Description of metric',
    '# TYPE dxspider_custom_metric gauge',
    'dxspider_custom_metric{label="value"} %d',
    $your_value
);
```

### Creating Custom Dashboards

1. Create dashboard in Grafana UI
2. Export as JSON
3. Save to `metrics/grafana/dashboards/`
4. Dashboard will auto-load on container restart

### Adding Alerts

Create alert rules in `metrics/prometheus/alerts/`:

```yaml
# Example: High spot rate alert
groups:
  - name: dxspider_alerts
    interval: 30s
    rules:
      - alert: HighSpotRate
        expr: dxspider_spots_per_minute > 50
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High DX spot rate detected"
          description: "Spot rate is {{ $value }} spots/min"
```

Then update `prometheus.yml`:

```yaml
rule_files:
  - "alerts/*.yml"
```

## Monitoring Best Practices

### Resource Limits

The docker-compose configuration includes resource limits:

- **DXSpider**: 512MB RAM, 2 CPUs
- **Prometheus**: 1GB RAM, 1 CPU (stores 30 days of metrics)
- **Grafana**: 512MB RAM, 1 CPU

### Data Retention

Prometheus retains metrics for 30 days by default. Adjust in `docker-compose.metrics.yml`:

```yaml
command:
  - '--storage.tsdb.retention.time=90d'  # 90 days
  - '--storage.tsdb.retention.size=50GB' # 50GB max
```

### Backup

Backup Prometheus data:

```bash
# Stop Prometheus
docker compose stop prometheus

# Backup data
docker run --rm -v dxspider_prometheus_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/prometheus-backup.tar.gz -C /data .

# Restart Prometheus
docker compose start prometheus
```

Backup Grafana data:

```bash
docker run --rm -v dxspider_grafana_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup.tar.gz -C /data .
```

## Troubleshooting

### Metrics Not Appearing

1. **Check metrics server is running**:
   ```bash
   docker compose logs dxspider | grep metrics
   ```

2. **Test metrics endpoint**:
   ```bash
   curl http://localhost:9100/metrics
   ```

3. **Check Prometheus targets**:
   - Go to http://localhost:9090/targets
   - Ensure `dxspider` target is "UP"

### Grafana Shows No Data

1. **Check Prometheus datasource**:
   - Go to **Configuration** → **Data Sources**
   - Test Prometheus connection

2. **Verify time range**:
   - Ensure dashboard time range includes recent data
   - Default is "Last 1 hour"

3. **Check metric names**:
   - In Prometheus UI, verify metrics exist: http://localhost:9090/graph

### High Memory Usage

If Prometheus uses too much memory:

1. **Reduce retention**:
   ```yaml
   - '--storage.tsdb.retention.time=7d'  # Shorter retention
   ```

2. **Reduce scrape interval**:
   ```yaml
   scrape_interval: 30s  # Less frequent scraping
   ```

3. **Increase cache TTL** in metrics_server.pl:
   ```perl
   my $cache_ttl = 10; # Cache for 10 seconds instead of 5
   ```

### Permission Errors

If you see permission errors:

```bash
# Fix ownership
docker compose down
sudo chown -R 1000:1000 metrics/
docker compose up -d
```

## Advanced Features

### Adding Node Exporter

To monitor system resources (CPU, memory, disk):

1. Uncomment `node-exporter` service in `docker-compose.metrics.yml`
2. Add to Prometheus targets in `prometheus.yml`
3. Import Node Exporter dashboard in Grafana (ID: 1860)

### Remote Monitoring

To expose metrics to external Prometheus:

1. **Expose metrics port**:
   ```yaml
   # In docker-compose.metrics.yml
   ports:
     - "0.0.0.0:9100:9100"  # Accessible from network
   ```

2. **Add firewall rule**:
   ```bash
   sudo ufw allow 9100/tcp
   ```

3. **Configure remote Prometheus**:
   ```yaml
   scrape_configs:
     - job_name: 'dxspider-remote'
       static_configs:
         - targets: ['your-server:9100']
   ```

### Grafana Alerting

Configure alerts in Grafana:

1. Go to **Alerting** → **Notification channels**
2. Add email, Slack, or other notification channel
3. Create alert rules in dashboard panels
4. Set thresholds and notification preferences

## Performance Impact

The metrics solution is designed for minimal performance impact:

- **Metrics Server**:
  - ~10MB RAM
  - <1% CPU (with caching)
  - Non-blocking I/O

- **Metrics Collection**:
  - 5-second cache reduces DXSpider queries
  - Read-only operations on DXSpider internals
  - No impact on spot processing or routing

- **Network Overhead**:
  - ~2KB per scrape
  - Default 15s interval = ~8KB/min

## Security Considerations

### Production Deployment

For production use:

1. **Change default passwords**:
   ```bash
   # .env
   GF_ADMIN_PASSWORD=strong_random_password
   ```

2. **Enable HTTPS** (use reverse proxy):
   ```nginx
   # nginx example
   location /grafana/ {
       proxy_pass http://localhost:3000/;
   }
   ```

3. **Restrict access**:
   ```yaml
   # docker-compose.metrics.yml
   ports:
     - "127.0.0.1:3000:3000"  # Localhost only
   ```

4. **Disable anonymous access**:
   ```bash
   GF_AUTH_ANONYMOUS_ENABLED=false
   ```

### Firewall Rules

```bash
# Allow only from monitoring server
sudo ufw allow from monitoring_server_ip to any port 9100
sudo ufw allow from monitoring_server_ip to any port 9090
sudo ufw allow from monitoring_server_ip to any port 3000
```

## Support and Contribution

- **Issues**: Report bugs on GitHub
- **Discussions**: Share custom dashboards and metrics
- **Documentation**: Contribute improvements to this README

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Mojolicious Documentation](https://docs.mojolicious.org/)
- [DXSpider Documentation](http://www.dxcluster.org/)

## License

This metrics implementation is part of the 9M2PJU-DXSpider-Docker project and follows the same license as the main project.
