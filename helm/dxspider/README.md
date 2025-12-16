# DXSpider Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/dxspider)](https://artifacthub.io/packages/helm/dxspider/dxspider)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready Helm chart for deploying [DXSpider](http://www.dxcluster.org/), a DX Cluster software used by amateur radio operators worldwide to share real-time DX spotting information.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick Start](#quick-start)
  - [Production Deployment](#production-deployment)
- [Configuration](#configuration)
  - [Required Parameters](#required-parameters)
  - [Common Configuration Examples](#common-configuration-examples)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Features

- **Production-Ready**: StatefulSet-based deployment with persistent storage
- **Highly Configurable**: Extensive configuration options via values.yaml
- **Security Focused**: Non-root containers, security contexts, and secrets management
- **Monitoring Ready**: Prometheus ServiceMonitor integration
- **Ingress Support**: Both nginx and traefik ingress controllers
- **Health Checks**: Comprehensive liveness, readiness, and startup probes
- **Resource Management**: Configurable CPU and memory limits/requests
- **Flexible Networking**: ClusterIP, NodePort, or LoadBalancer service types

## Prerequisites

- Kubernetes 1.23+
- Helm 3.x
- PersistentVolume provisioner (if using persistent storage)
- (Optional) Prometheus Operator (for ServiceMonitor)
- (Optional) cert-manager (for TLS certificates)

## Installation

### Quick Start

1. **Add the Helm repository** (if published):

```bash
helm repo add dxspider https://9m2pju.github.io/9M2PJU-DXSpider-Docker
helm repo update
```

2. **Create a namespace**:

```bash
kubectl create namespace dxspider
```

3. **Install the chart with default values**:

```bash
helm install my-dxspider dxspider/dxspider --namespace dxspider
```

4. **Or install from local chart**:

```bash
# Clone the repository
git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
cd 9M2PJU-DXSpider-Docker/helm

# Install the chart
helm install my-dxspider ./dxspider --namespace dxspider
```

### Production Deployment

For production deployments, use the production values file:

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --values ./dxspider/values-production.yaml \
  --set cluster.callsign="YOUR-CALLSIGN-10" \
  --set sysop.callsign="YOUR-CALLSIGN" \
  --set sysop.email="your@email.com" \
  --set cluster.location.locator="AB12CD" \
  --set cluster.location.qth="Your Location" \
  --set ingress.hosts[0].host="dxspider.yourdomain.com" \
  --set ingress.tls[0].hosts[0]="dxspider.yourdomain.com"
```

## Configuration

### Required Parameters

The following parameters must be configured:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `cluster.callsign` | Node callsign (with SSID) | `9M2PJU-10` |
| `sysop.callsign` | Sysop callsign | `9M2PJU` |
| `cluster.location.locator` | Maidenhead grid locator | `OJ03UD` |
| `cluster.location.qth` | Location description | `Kuala Lumpur, Malaysia` |

### Key Configuration Parameters

#### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | DXSpider image repository | `9m2pju/dxspider` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

#### Cluster Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cluster.callsign` | Node callsign | `9M2PJU-10` |
| `cluster.branch` | DXSpider branch (mojo/master) | `mojo` |
| `cluster.location.latitude` | Latitude in decimal degrees | `+51.5` |
| `cluster.location.longitude` | Longitude in decimal degrees | `-0.13` |
| `cluster.location.locator` | Grid locator | `OJ03UD` |
| `cluster.location.qth` | Location description | `Kuala Lumpur, Malaysia` |
| `cluster.network.port` | Telnet port | `7300` |
| `cluster.network.sysopPort` | Web console port | `8050` |
| `cluster.network.metricsPort` | Metrics port | `9100` |

#### Sysop Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sysop.name` | Sysop name | `Piju` |
| `sysop.callsign` | Sysop callsign | `9M2PJU` |
| `sysop.email` | Sysop email | `9m2pju@hamradio.my` |
| `sysop.password` | Web console password | `""` (auto-generated) |

#### Persistence Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.storageClass` | Storage class name | `""` |
| `persistence.size` | Storage size | `10Gi` |
| `persistence.accessMode` | Access mode | `ReadWriteOnce` |

#### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.telnet.port` | Telnet service port | `7300` |
| `service.console.port` | Console service port | `8050` |
| `service.metrics.port` | Metrics service port | `9100` |

#### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts` | Ingress hosts | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

#### Resources Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `2000m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `128Mi` |

#### Metrics Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `metrics.enabled` | Enable metrics | `false` |
| `metrics.serviceMonitor.enabled` | Create ServiceMonitor | `false` |
| `metrics.serviceMonitor.interval` | Scrape interval | `30s` |

### Common Configuration Examples

#### 1. Basic Installation with Custom Callsign

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set cluster.callsign="K1ABC-5" \
  --set sysop.callsign="K1ABC" \
  --set cluster.location.locator="FN42AA" \
  --set cluster.location.qth="Boston, MA"
```

#### 2. Enable Ingress with TLS

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set ingress.enabled=true \
  --set ingress.className="nginx" \
  --set ingress.hosts[0].host="dxspider.example.com" \
  --set ingress.hosts[0].paths[0].path="/console" \
  --set ingress.hosts[0].paths[0].pathType="Prefix" \
  --set ingress.hosts[0].paths[0].service="console" \
  --set ingress.tls[0].secretName="dxspider-tls" \
  --set ingress.tls[0].hosts[0]="dxspider.example.com"
```

#### 3. Enable Prometheus Monitoring

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set metrics.enabled=true \
  --set metrics.serviceMonitor.enabled=true \
  --set metrics.serviceMonitor.additionalLabels.prometheus="kube-prometheus"
```

#### 4. Configure Partner Node Connections

Create a custom values file `my-values.yaml`:

```yaml
config:
  connections:
    9m2pju-2:
      timeout 15
      connect telnet dx.example.com 7300
      'login:' '9M2PJU-10'
    gb7dx:
      timeout 15
      connect telnet gb7dx.dxcluster.org 8000
      'login:' '9M2PJU-10'
```

Install with custom values:

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --values my-values.yaml
```

#### 5. Use LoadBalancer Service

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set service.type="LoadBalancer" \
  --set service.loadBalancerSourceRanges[0]="203.0.113.0/24"
```

#### 6. Enable Database Support

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set database.enabled=true \
  --set database.hostname="mariadb.database.svc.cluster.local" \
  --set database.password="your-secure-password"
```

## Upgrading

### Upgrade to a New Version

```bash
# Update the Helm repository
helm repo update

# Upgrade the release
helm upgrade my-dxspider dxspider/dxspider \
  --namespace dxspider \
  --reuse-values
```

### Upgrade with New Values

```bash
helm upgrade my-dxspider dxspider/dxspider \
  --namespace dxspider \
  --values my-values.yaml
```

### Rollback to Previous Version

```bash
# List release history
helm history my-dxspider --namespace dxspider

# Rollback to previous revision
helm rollback my-dxspider --namespace dxspider

# Rollback to specific revision
helm rollback my-dxspider 2 --namespace dxspider
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-dxspider --namespace dxspider

# Delete the namespace (optional)
kubectl delete namespace dxspider

# Note: PersistentVolumeClaims are not automatically deleted
# Delete PVCs manually if you want to remove all data
kubectl delete pvc --namespace dxspider --all
```

## Architecture

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │             Namespace: dxspider                    │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │          StatefulSet: dxspider             │ │    │
│  │  │  ┌────────────────────────────────────┐    │ │    │
│  │  │  │     Pod: dxspider-0                │    │ │    │
│  │  │  │  ┌──────────────────────────────┐  │    │ │    │
│  │  │  │  │  Container: dxspider        │  │    │ │    │
│  │  │  │  │  - DXSpider cluster.pl      │  │    │ │    │
│  │  │  │  │  - ttyd web console         │  │    │ │    │
│  │  │  │  │  Ports:                     │  │    │ │    │
│  │  │  │  │  - 7300 (telnet)            │  │    │ │    │
│  │  │  │  │  - 8050 (console)           │  │    │ │    │
│  │  │  │  │  - 9100 (metrics)           │  │    │ │    │
│  │  │  │  └──────────────────────────────┘  │    │ │    │
│  │  │  │                                     │    │ │    │
│  │  │  │  Volumes:                           │    │ │    │
│  │  │  │  - data (PVC)                       │    │ │    │
│  │  │  │  - config (ConfigMap)               │    │ │    │
│  │  │  └────────────────────────────────────┘    │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │        Service: dxspider                    │ │    │
│  │  │  - telnet:7300                              │ │    │
│  │  │  - console:8050                             │ │    │
│  │  │  - metrics:9100                             │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │        Ingress: dxspider                    │ │    │
│  │  │  - /console -> console:8050                 │ │    │
│  │  │  - /metrics -> metrics:9100                 │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │     ConfigMap: dxspider-config              │ │    │
│  │  │  - startup                                   │ │    │
│  │  │  - crontab                                   │ │    │
│  │  │  - motd                                      │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │     Secret: dxspider-secret                 │ │    │
│  │  │  - sysop-password                            │ │    │
│  │  │  - database-password                         │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐ │    │
│  │  │     PVC: data-dxspider-0                    │ │    │
│  │  │  - Size: 10Gi (configurable)                │ │    │
│  │  │  - Mount: /spider/local_data                │ │    │
│  │  └──────────────────────────────────────────────┘ │    │
│  │                                                     │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Why StatefulSet?

DXSpider is deployed as a **StatefulSet** rather than a Deployment because:

1. **Stable Network Identity**: Each DXSpider node needs a consistent hostname for partner node connections
2. **Ordered Deployment**: StatefulSets ensure predictable pod naming and ordering
3. **Persistent Storage**: Automatic PVC management with volumeClaimTemplates
4. **Single Instance**: DXSpider doesn't support horizontal scaling (replicas: 1)

## Troubleshooting

### Common Issues

#### 1. Pod Not Starting

Check pod status:
```bash
kubectl get pods --namespace dxspider
kubectl describe pod dxspider-0 --namespace dxspider
```

Check logs:
```bash
kubectl logs dxspider-0 --namespace dxspider -f
```

Common causes:
- Insufficient resources (check resource limits)
- PVC not binding (check storage class)
- Configuration errors (check ConfigMap)

#### 2. Cannot Connect via Telnet

Port forwarding for testing:
```bash
kubectl port-forward --namespace dxspider service/dxspider 7300:7300
telnet localhost 7300
```

Check service:
```bash
kubectl get service --namespace dxspider
kubectl describe service dxspider --namespace dxspider
```

#### 3. Persistence Issues

Check PVC status:
```bash
kubectl get pvc --namespace dxspider
kubectl describe pvc data-dxspider-0 --namespace dxspider
```

List available storage classes:
```bash
kubectl get storageclass
```

#### 4. Web Console Access Issues

Check if ttyd is running:
```bash
kubectl exec -it dxspider-0 --namespace dxspider -- pgrep ttyd
```

Retrieve sysop password:
```bash
kubectl get secret dxspider-secret --namespace dxspider -o jsonpath="{.data.sysop-password}" | base64 --decode
```

#### 5. Ingress Not Working

Check ingress status:
```bash
kubectl get ingress --namespace dxspider
kubectl describe ingress dxspider --namespace dxspider
```

Verify ingress controller is installed:
```bash
kubectl get pods --all-namespaces | grep ingress
```

### Debug Mode

Execute shell in the container:
```bash
kubectl exec -it dxspider-0 --namespace dxspider -- /bin/sh
```

Common debug commands inside the container:
```bash
# Check if DXSpider is running
pgrep -f cluster.pl

# Check listening ports
netstat -tlnp

# Test telnet connectivity
nc -z localhost 7300

# View DXSpider logs
tail -f /spider/local_data/log/$(date +%Y%m%d)_debug.log

# View ttyd logs
ps aux | grep ttyd
```

### Getting Help

- **Project Issues**: https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues
- **DXSpider Documentation**: http://www.dxcluster.org/
- **Helm Documentation**: https://helm.sh/docs/

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This Helm chart is licensed under the MIT License. See the [LICENSE](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/blob/main/LICENSE) file for details.

DXSpider itself is licensed under the GPL. See the DXSpider project for more information.

## Maintainers

- **9M2PJU** - [9m2pju@hamradio.my](mailto:9m2pju@hamradio.my)

## Acknowledgments

- DXSpider created by Dirk Koopman (G1TLH)
- Docker implementation by 9M2PJU
- Helm chart maintained by the 9M2PJU team

---

**73 and happy DXing!**
