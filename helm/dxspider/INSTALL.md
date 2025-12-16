# Quick Installation Guide

## Prerequisites

- Kubernetes cluster (1.23+)
- Helm 3.x installed
- kubectl configured to access your cluster
- (Optional) Storage class for persistent volumes

## Basic Installation

### 1. Create Namespace

```bash
kubectl create namespace dxspider
```

### 2. Install Chart (Local)

```bash
# From the repository root
cd helm
helm install my-dxspider ./dxspider --namespace dxspider
```

### 3. Customize Installation

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --set cluster.callsign="YOUR-CALLSIGN-10" \
  --set sysop.callsign="YOUR-CALLSIGN" \
  --set sysop.email="your@email.com" \
  --set cluster.location.locator="AB12CD" \
  --set cluster.location.qth="Your City, Country"
```

## Production Installation

```bash
helm install my-dxspider ./dxspider \
  --namespace dxspider \
  --values ./dxspider/values-production.yaml \
  --set cluster.callsign="YOUR-CALLSIGN-10" \
  --set sysop.callsign="YOUR-CALLSIGN" \
  --set sysop.email="your@email.com" \
  --set cluster.location.locator="AB12CD" \
  --set cluster.location.qth="Your City, Country" \
  --set sysop.password="your-secure-password" \
  --set ingress.hosts[0].host="dxspider.yourdomain.com" \
  --set ingress.tls[0].hosts[0]="dxspider.yourdomain.com"
```

## Verify Installation

### Check Pod Status

```bash
kubectl get pods --namespace dxspider
```

Expected output:
```
NAME          READY   STATUS    RESTARTS   AGE
dxspider-0    1/1     Running   0          2m
```

### Check Logs

```bash
kubectl logs --namespace dxspider dxspider-0 -f
```

### Test Telnet Connection

```bash
# Port forward the telnet port
kubectl port-forward --namespace dxspider service/my-dxspider 7300:7300

# In another terminal, connect via telnet
telnet localhost 7300
```

## Access Web Console

### Port Forwarding

```bash
kubectl port-forward --namespace dxspider service/my-dxspider 8050:8050
```

Then open http://localhost:8050 in your browser.

### Get Sysop Password

```bash
kubectl get secret --namespace dxspider my-dxspider-secret \
  -o jsonpath="{.data.sysop-password}" | base64 --decode
echo
```

## Uninstall

```bash
# Remove the release
helm uninstall my-dxspider --namespace dxspider

# Delete namespace
kubectl delete namespace dxspider

# Delete PVCs (if you want to remove all data)
kubectl delete pvc --namespace dxspider --all
```

## Upgrade

```bash
# Upgrade with new values
helm upgrade my-dxspider ./dxspider \
  --namespace dxspider \
  --reuse-values \
  --set image.tag="new-version"

# Rollback if needed
helm rollback my-dxspider --namespace dxspider
```

## Troubleshooting

### Pod Not Starting

```bash
kubectl describe pod dxspider-0 --namespace dxspider
kubectl logs dxspider-0 --namespace dxspider
```

### PVC Issues

```bash
kubectl get pvc --namespace dxspider
kubectl describe pvc data-my-dxspider-0 --namespace dxspider
```

### Service Not Accessible

```bash
kubectl get service --namespace dxspider
kubectl describe service my-dxspider --namespace dxspider
```

## Next Steps

- Configure partner node connections (see README.md)
- Enable Ingress for external access
- Set up Prometheus monitoring
- Configure backups for persistent data

For detailed documentation, see [README.md](README.md)
