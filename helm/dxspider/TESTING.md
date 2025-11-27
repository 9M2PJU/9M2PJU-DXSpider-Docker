# Testing Guide for DXSpider Helm Chart

This document provides comprehensive testing procedures for the DXSpider Helm chart.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Validation Tests](#validation-tests)
- [Installation Tests](#installation-tests)
- [Functional Tests](#functional-tests)
- [Security Tests](#security-tests)
- [Performance Tests](#performance-tests)
- [Upgrade Tests](#upgrade-tests)
- [Cleanup](#cleanup)

## Prerequisites

### Required Tools

```bash
# Verify required tools are installed
helm version
kubectl version
telnet --version  # or nc (netcat)
```

### Test Environment

- Kubernetes cluster (local or remote)
- kubectl configured to access the cluster
- Sufficient resources (2 CPU, 1Gi RAM minimum)
- Storage provisioner (if testing persistence)

### Create Test Namespace

```bash
kubectl create namespace dxspider-test
```

## Validation Tests

### 1. Helm Lint

Validate chart structure and syntax:

```bash
cd helm/dxspider
helm lint .
```

Expected output: No errors, warnings are acceptable.

### 2. Template Rendering

Test template rendering with default values:

```bash
helm template test-release . --namespace dxspider-test
```

Expected: All templates render without errors.

### 3. Template Rendering with Production Values

```bash
helm template test-release . --namespace dxspider-test -f values-production.yaml
```

Expected: All templates render without errors.

### 4. Schema Validation

If using Helm 3.5+, test values schema validation:

```bash
# This should pass
helm lint . --strict

# Test with invalid values (should fail)
helm template test . --set cluster.callsign="invalid" 2>&1 | grep -i "schema"
```

### 5. Dry Run Installation

```bash
helm install test-release . \
  --namespace dxspider-test \
  --dry-run \
  --debug
```

Expected: Installation simulates successfully.

## Installation Tests

### Test 1: Basic Installation (Default Values)

```bash
# Install with default values
helm install test-basic . --namespace dxspider-test

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/test-basic-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify installation
kubectl get all --namespace dxspider-test

# Check logs
kubectl logs test-basic-0 --namespace dxspider-test

# Cleanup
helm uninstall test-basic --namespace dxspider-test
```

### Test 2: Installation with Custom Values

```bash
# Create custom values file
cat > test-values.yaml <<EOF
cluster:
  callsign: "TEST-99"
  location:
    locator: "AA00AA"
    qth: "Test Location"
sysop:
  callsign: "TEST"
  email: "test@example.com"
persistence:
  enabled: false
EOF

# Install with custom values
helm install test-custom . \
  --namespace dxspider-test \
  -f test-values.yaml

# Wait and verify
kubectl wait --for=condition=ready pod/test-custom-0 \
  --namespace dxspider-test \
  --timeout=300s

# Cleanup
helm uninstall test-custom --namespace dxspider-test
rm test-values.yaml
```

### Test 3: Installation with Production Values

```bash
helm install test-prod . \
  --namespace dxspider-test \
  -f values-production.yaml \
  --set cluster.callsign="PROD-10" \
  --set sysop.callsign="PROD"

# Wait and verify
kubectl wait --for=condition=ready pod/test-prod-0 \
  --namespace dxspider-test \
  --timeout=300s

# Cleanup
helm uninstall test-prod --namespace dxspider-test
```

## Functional Tests

### Test 4: Telnet Connectivity

```bash
# Install chart
helm install test-telnet . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-telnet-0 \
  --namespace dxspider-test \
  --timeout=300s

# Port forward telnet port
kubectl port-forward --namespace dxspider-test svc/test-telnet 7300:7300 &
PF_PID=$!

# Wait for port forward to establish
sleep 5

# Test telnet connection
echo "Testing telnet connectivity..."
(echo "quit"; sleep 2) | telnet localhost 7300

# Cleanup
kill $PF_PID
helm uninstall test-telnet --namespace dxspider-test
```

### Test 5: Web Console Access

```bash
# Install chart
helm install test-console . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-console-0 \
  --namespace dxspider-test \
  --timeout=300s

# Port forward console port
kubectl port-forward --namespace dxspider-test svc/test-console 8050:8050 &
PF_PID=$!

# Wait for port forward
sleep 5

# Test HTTP access
curl -s -o /dev/null -w "%{http_code}" http://localhost:8050/

# Expected: 200 or 401 (if auth required)

# Get sysop password
kubectl get secret test-console-secret \
  --namespace dxspider-test \
  -o jsonpath="{.data.sysop-password}" | base64 --decode

# Cleanup
kill $PF_PID
helm uninstall test-console --namespace dxspider-test
```

### Test 6: Persistence

```bash
# Install with persistence enabled
helm install test-persist . \
  --namespace dxspider-test \
  --set persistence.enabled=true \
  --set persistence.size=1Gi

# Wait for pod
kubectl wait --for=condition=ready pod/test-persist-0 \
  --namespace dxspider-test \
  --timeout=300s

# Check PVC
kubectl get pvc --namespace dxspider-test

# Verify PVC is bound
kubectl get pvc data-test-persist-0 \
  --namespace dxspider-test \
  -o jsonpath='{.status.phase}'

# Expected: Bound

# Write test data
kubectl exec test-persist-0 --namespace dxspider-test -- \
  sh -c 'echo "test data" > /spider/local_data/test.txt'

# Delete pod (StatefulSet will recreate it)
kubectl delete pod test-persist-0 --namespace dxspider-test

# Wait for new pod
kubectl wait --for=condition=ready pod/test-persist-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify data persisted
kubectl exec test-persist-0 --namespace dxspider-test -- \
  cat /spider/local_data/test.txt

# Expected: "test data"

# Cleanup
helm uninstall test-persist --namespace dxspider-test
kubectl delete pvc data-test-persist-0 --namespace dxspider-test
```

### Test 7: ConfigMap Updates

```bash
# Install chart
helm install test-config . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-config-0 \
  --namespace dxspider-test \
  --timeout=300s

# Update configuration
helm upgrade test-config . \
  --namespace dxspider-test \
  --set config.motd="Updated MOTD"

# Wait for pod to restart
sleep 10
kubectl wait --for=condition=ready pod/test-config-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify config update
kubectl exec test-config-0 --namespace dxspider-test -- \
  cat /spider/local_data/motd | grep "Updated MOTD"

# Cleanup
helm uninstall test-config --namespace dxspider-test
```

## Security Tests

### Test 8: Security Context

```bash
# Install chart
helm install test-security . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-security-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify pod runs as non-root
kubectl exec test-security-0 --namespace dxspider-test -- id

# Expected: uid=1000

# Verify security context
kubectl get pod test-security-0 \
  --namespace dxspider-test \
  -o jsonpath='{.spec.securityContext}'

# Cleanup
helm uninstall test-security --namespace dxspider-test
```

### Test 9: Secret Management

```bash
# Install chart
helm install test-secret . --namespace dxspider-test

# Verify secret exists
kubectl get secret test-secret-secret --namespace dxspider-test

# Verify secret contains required keys
kubectl get secret test-secret-secret \
  --namespace dxspider-test \
  -o jsonpath='{.data}' | grep -q "sysop-password"

# Cleanup
helm uninstall test-secret --namespace dxspider-test
```

## Performance Tests

### Test 10: Resource Limits

```bash
# Install with resource limits
helm install test-resources . \
  --namespace dxspider-test \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=256Mi \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=64Mi

# Wait for pod
kubectl wait --for=condition=ready pod/test-resources-0 \
  --namespace dxspider-test \
  --timeout=300s

# Check resource usage
kubectl top pod test-resources-0 --namespace dxspider-test

# Cleanup
helm uninstall test-resources --namespace dxspider-test
```

### Test 11: Health Checks

```bash
# Install chart
helm install test-health . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-health-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify probes are configured
kubectl get pod test-health-0 \
  --namespace dxspider-test \
  -o jsonpath='{.spec.containers[0].livenessProbe}'

kubectl get pod test-health-0 \
  --namespace dxspider-test \
  -o jsonpath='{.spec.containers[0].readinessProbe}'

# Check pod events for probe activity
kubectl describe pod test-health-0 --namespace dxspider-test | grep -A5 "Probes"

# Cleanup
helm uninstall test-health --namespace dxspider-test
```

## Upgrade Tests

### Test 12: Upgrade from Previous Version

```bash
# Install initial version
helm install test-upgrade . --namespace dxspider-test

# Wait for pod
kubectl wait --for=condition=ready pod/test-upgrade-0 \
  --namespace dxspider-test \
  --timeout=300s

# Upgrade with new values
helm upgrade test-upgrade . \
  --namespace dxspider-test \
  --set image.tag="new-version" \
  --set cluster.location.qth="Updated Location"

# Wait for upgrade
kubectl wait --for=condition=ready pod/test-upgrade-0 \
  --namespace dxspider-test \
  --timeout=300s

# Verify upgrade
helm history test-upgrade --namespace dxspider-test

# Rollback test
helm rollback test-upgrade --namespace dxspider-test

# Wait for rollback
kubectl wait --for=condition=ready pod/test-upgrade-0 \
  --namespace dxspider-test \
  --timeout=300s

# Cleanup
helm uninstall test-upgrade --namespace dxspider-test
```

## Cleanup

### Clean Up Test Resources

```bash
# Uninstall all releases in test namespace
helm list --namespace dxspider-test -q | xargs -I {} helm uninstall {} --namespace dxspider-test

# Delete PVCs
kubectl delete pvc --all --namespace dxspider-test

# Delete namespace
kubectl delete namespace dxspider-test
```

## Automated Testing Script

Create a comprehensive test script:

```bash
#!/bin/bash
# test-all.sh - Run all Helm chart tests

set -e

NAMESPACE="dxspider-test"
CHART_PATH="."

echo "Starting DXSpider Helm Chart Tests..."

# Validation
echo "==> Running validation tests..."
helm lint $CHART_PATH
helm template test $CHART_PATH --namespace $NAMESPACE > /dev/null

# Installation
echo "==> Testing basic installation..."
helm install test-basic $CHART_PATH --namespace $NAMESPACE --wait

# Functional tests
echo "==> Testing connectivity..."
kubectl wait --for=condition=ready pod/test-basic-0 --namespace $NAMESPACE --timeout=300s

# Cleanup
echo "==> Cleaning up..."
helm uninstall test-basic --namespace $NAMESPACE

echo "All tests passed!"
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Helm Chart Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: azure/setup-helm@v3
      - name: Lint
        run: helm lint helm/dxspider
      - name: Template
        run: helm template test helm/dxspider
```

## Reporting Issues

If any tests fail, collect the following information:

1. Helm version: `helm version`
2. Kubernetes version: `kubectl version`
3. Pod logs: `kubectl logs <pod-name> --namespace dxspider-test`
4. Pod description: `kubectl describe pod <pod-name> --namespace dxspider-test`
5. Helm values used: `helm get values <release> --namespace dxspider-test`

Report issues at: https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues
