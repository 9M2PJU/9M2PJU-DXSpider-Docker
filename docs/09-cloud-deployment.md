# Cloud Deployment

This guide covers deploying 9M2PJU DXSpider Docker on popular cloud providers (AWS, GCP, Azure) and VPS providers (DigitalOcean, Hetzner, Linode).

---

## General Cloud Considerations

### Resource Requirements

DXSpider is lightweight. A minimum-spec VPS is sufficient for a personal or small club node:

| Resource | Minimum | Recommended |
| :--- | :--- | :--- |
| CPU | 1 vCPU | 2 vCPU |
| RAM | 512 MB | 1 GB |
| Disk | 5 GB | 10 GB (for log retention) |
| Network | 100 Mbps | 1 Gbps |
| OS | Any Linux with Docker | Ubuntu 22.04+ or Debian 12+ |

### Network Requirements

- **Public IP address** - Users connect from the internet.
- **Open port 7300/tcp** - For DX Cluster telnet connections.
- **Open port 8080/tcp** (optional) - For web console (restrict to your IP).
- **Low latency** - Choose a region close to your users or partner nodes.

### Static vs. Dynamic IP

A **static public IP** is strongly recommended. Partner nodes need to connect to a stable hostname. If you have a dynamic IP, use a dynamic DNS service (e.g., DuckDNS, No-IP) and update your partner connect scripts accordingly.

---

## AWS Deployment

### Option A: EC2 Instance

1. **Launch an EC2 instance**:
   - AMI: Ubuntu Server 22.04 LTS (or newer)
   - Instance type: `t3.micro` (2 vCPU, 1 GB RAM) - sufficient for small nodes
   - Storage: 8 GB gp3
   - Enable Auto-assign Public IP

2. **Configure Security Group**:
   | Port | Protocol | Source | Purpose |
   | :--- | :--- | :--- | :--- |
   | 22 | TCP | Your IP | SSH |
   | 7300 | TCP | 0.0.0.0/0 | DX Cluster |
   | 8080 | TCP | Your IP | Web Console (optional) |

3. **Connect and install Docker**:
   ```bash
   ssh -i your-key.pem ubuntu@<ec2-public-ip>
   sudo apt update && sudo apt install -y docker.io docker compose-v2 git
   sudo usermod -aG docker ubuntu
   # Log out and back in for group change to take effect
   ```

4. **Clone and configure**:
   ```bash
   git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
   cd 9M2PJU-DXSpider-Docker
   cp .env.example .env
   nano .env  # Set your callsign, locator, etc.
   ```

5. **Launch**:
   ```bash
   docker compose pull      # Download pre-built image from GHCR
   docker compose up -d     # Start the cluster
   ```

6. **Associate an Elastic IP** (static IP):
   - In the AWS Console, allocate an Elastic IP and associate it with your instance.
   - Use this IP (or a DNS name pointing to it) in partner connect scripts.

### Option B: AWS Lightsail

AWS Lightsail is simpler and cheaper for small nodes:

1. Create a Lightsail instance (Ubuntu 22.04, 1 GB RAM plan ~$5/mo).
2. In the Networking tab, add firewall rules for ports 7300 and 8080.
3. SSH in and follow steps 4-5 above.

---

## GCP Deployment

1. **Create a VM instance**:
   - Machine type: `e2-micro` (2 vCPU, 1 GB RAM)
   - Boot disk: Ubuntu 22.04 LTS, 10 GB
   - Allow HTTP/HTTPS traffic (optional, for web console)
   - Enable External IP (static recommended)

2. **Configure Firewall**:
   ```bash
   # In GCP Console → VPC Network → Firewall
   # Create rule: allow-tcp-7300, source: 0.0.0.0/0, port: 7300
   # Create rule: allow-tcp-8080, source: YOUR_IP/32, port: 8080
   ```

3. **Connect via SSH** (browser-based SSH or `gcloud compute ssh`).

4. **Install Docker and deploy** (same as AWS steps 3-5).

5. **Reserve a Static IP**:
   - In GCP Console → VPC Network → IP addresses
   - Promote your instance's ephemeral IP to static.

---

## Azure Deployment

1. **Create a VM**:
   - Image: Ubuntu Server 22.04 LTS
   - Size: `B2s` (2 vCPU, 4 GB RAM) or `B1s` (1 vCPU, 1 GB RAM)
   - Authentication: SSH key
   - Public IP: Static

2. **Configure Network Security Group**:
   | Port | Protocol | Source | Purpose |
   | :--- | :--- | :--- | :--- |
   | 22 | TCP | Your IP | SSH |
   | 7300 | TCP | 0.0.0.0/0 | DX Cluster |
   | 8080 | TCP | Your IP | Web Console |

3. **Connect and deploy** (same as AWS steps 3-5).

---

## DigitalOcean / Hetzner / Linode

These VPS providers are popular for DX Cluster nodes due to low cost and simplicity.

### DigitalOcean

1. Create a Droplet (Ubuntu 22.04, 1 GB RAM, $6/mo).
2. Add a firewall: allow 22, 7300, 8080 (restrict 8080).
3. SSH in and deploy.

### Hetzner Cloud

1. Create a server (CX22, 2 vCPU, 4 GB RAM, ~€4/mo).
2. Configure firewall in Hetzner Cloud console.
3. SSH in and deploy.

### Linode (Akamai)

1. Create a Linode (Nanode 1 GB, $5/mo).
3. Configure firewall (Cloud Firewall or iptables).
4. SSH in and deploy.

---

## DNS Configuration

Point a domain name to your server for easier partner connections:

```
cluster.yourdomain.com.   IN   A   YOUR.SERVER.IP
```

Then in partner connect scripts, use the hostname:
```bash
connect telnet cluster.yourdomain.com 7300
```

---

## Persistence in the Cloud

All cloud deployments use the same bind-mount structure as local deployments. Your data persists on the VM's disk:

```
./local_data/     # User databases, spots, logs
./local/          # DXVars.pm, Listeners.pm
./connect/        # Partner connection scripts
./startup/        # Startup commands
./local_cmd/      # Crontab and local commands
```

### Backing Up to Cloud Storage

Schedule regular backups of your `local_data/` directory:

```bash
# Daily backup to AWS S3
0 3 * * * tar czf /tmp/dxspider-backup.tar.gz /home/user/9M2PJU-DXSpider-Docker/local_data && aws s3 cp /tmp/dxspider-backup.tar.gz s3://your-bucket/dxspider/$(date +\%Y\%m\%d).tar.gz && rm /tmp/dxspider-backup.tar.gz
```

---

## Reverse Proxy (Optional)

If you want to put the web console behind HTTPS with a domain name, use a reverse proxy like Caddy, Nginx, or Traefik.

### Caddy Example

```caddyfile
cluster.yourdomain.com {
    reverse_proxy localhost:8080
    basicauth {
        admin $2a$14$...  # Generate with: caddy hash-password
    }
}
```

This gives you:
- HTTPS (automatic via Let's Encrypt)
- Domain name access instead of IP:port
- Additional authentication layer

---

## Monitoring

### Simple Health Check

Use the built-in healthcheck:
```bash
docker inspect dxspider --format '{{.State.Health.Status}}'
```

### Uptime Monitoring

Use a free service like UptimeRobot to monitor port 7300. Set up an alert if the port stops responding.

### Log Aggregation

For production deployments, consider sending logs to a logging service:

```yaml
services:
  dxspider:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Or use a log aggregator like Loki, Datadog, or CloudWatch.

---

## Cost Optimization

| Provider | Cheapest Option | Approx. Monthly Cost |
| :--- | :--- | :--- |
| Hetzner Cloud | CX22 (2 vCPU, 4 GB) | ~€4 |
| DigitalOcean | Basic Droplet (1 vCPU, 1 GB) | $6 |
| Linode | Nanode (1 vCPU, 1 GB) | $5 |
| AWS Lightsail | 1 GB plan | $5 |
| GCP | e2-micro (2 vCPU, 1 GB) | ~$7 |
| Azure | B1s (1 vCPU, 1 GB) | ~$4 |

> [!TIP]
> Hetzner Cloud offers the best value for DX Cluster nodes. EU regions have excellent connectivity to European cluster nodes.
