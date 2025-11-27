# Phase 4 Fix Checklist

Use this checklist to track resolution of QA issues. Check off items as they're completed.

---

## CRITICAL Issues (MUST FIX)

### CRIT-01: Dashboard CORS Wildcard
- [ ] Remove wildcard CORS from `dashboard/server/dashboard.pl:58`
- [ ] Add environment variable for allowed origins
- [ ] Update documentation with CORS configuration
- [ ] Test cross-origin requests are blocked
- **Assigned to:** Dashboard Team
- **Target:** 2025-11-28

### CRIT-02: Hardcoded Grafana Credentials
- [ ] Change default password to require explicit setting
- [ ] Add password validation in `metrics/docker-compose.metrics.yml`
- [ ] Update documentation with password setup
- [ ] Add password generation script/example
- **Assigned to:** Metrics Team
- **Target:** 2025-11-28

### CRIT-03: Dashboard Network Config
- [ ] Fix network configuration in `dashboard/docker-compose.dashboard.yml`
- [ ] Change `external: true` to `external: false`
- [ ] Remove hardcoded network name
- [ ] Test dashboard startup with main compose
- **Assigned to:** Dashboard Team
- **Target:** 2025-11-28

### CRIT-04: Dashboard Volume Paths
- [ ] Fix volume mount paths in `dashboard/docker-compose.dashboard.yml`
- [ ] Test from project root
- [ ] Test from dashboard directory
- [ ] Document correct usage
- **Assigned to:** Dashboard Team
- **Target:** 2025-11-28

### CRIT-05: Metrics Server Not in Container
- [ ] Add `COPY metrics/` to Dockerfile
- [ ] Ensure metrics server starts without compose override
- [ ] Test metrics endpoint in base container
- [ ] Update entrypoint.sh error handling
- **Assigned to:** Metrics Team
- **Target:** 2025-11-29

---

## HIGH Priority Issues (SHOULD FIX)

### HIGH-01: No Metrics Authentication
- [ ] Implement basic auth for metrics endpoint
- [ ] Add environment variables for auth credentials
- [ ] Update Prometheus config for auth
- [ ] Document authentication setup
- **Assigned to:** Metrics Team
- **Target:** 2025-11-30

### HIGH-02: Prometheus Wrong Service Name
- [ ] Update `metrics/prometheus/prometheus.yml` with correct target
- [ ] Make service name configurable
- [ ] Test metrics scraping
- [ ] Document network requirements
- **Assigned to:** Metrics Team
- **Target:** 2025-11-29

### HIGH-03: Notifications Not Integrated
- [ ] Add notification init to `entrypoint.sh`
- [ ] Test notification system starts automatically
- [ ] Verify graceful degradation if config missing
- [ ] Update integration documentation
- **Assigned to:** Notifications Team
- **Target:** 2025-11-30

### HIGH-04: Missing Perl Dependencies
- [ ] Add `perl-yaml-libyaml` to Dockerfile
- [ ] Add `perl-http-tiny` to Dockerfile
- [ ] Add `perl-json` to Dockerfile
- [ ] Add `perl-uri` to Dockerfile
- [ ] Test notification system loads
- **Assigned to:** Notifications Team
- **Target:** 2025-11-29

### HIGH-05: Dashboard No Rate Limiting
- [ ] Implement rate limiting in `dashboard/server/dashboard.pl`
- [ ] Add per-IP limits for API endpoints
- [ ] Make limits configurable
- [ ] Test rate limit enforcement
- **Assigned to:** Dashboard Team
- **Target:** 2025-12-01

### HIGH-06: Helm Missing Sidecars
- [ ] Add metrics sidecar to Helm chart
- [ ] Add dashboard deployment option
- [ ] Update Helm values.yaml
- [ ] Test Kubernetes deployment
- **Assigned to:** Helm Team
- **Target:** 2025-12-02

### HIGH-07: No Environment Validation
- [ ] Add validation for `CLUSTER_CALLSIGN`
- [ ] Add validation for webhook URLs
- [ ] Add validation for bot tokens
- [ ] Add clear error messages
- **Assigned to:** All Teams (coordination)
- **Target:** 2025-12-01

### HIGH-08: Metrics Cache Too Aggressive
- [ ] Change cache TTL from 5s to 30s
- [ ] Make cache TTL configurable
- [ ] Document caching behavior
- **Assigned to:** Metrics Team
- **Target:** 2025-11-30

### HIGH-09: Hardcoded Prometheus Values
- [ ] Make cluster label configurable
- [ ] Make environment label configurable
- [ ] Use environment variable substitution
- [ ] Document Prometheus configuration
- **Assigned to:** Metrics Team
- **Target:** 2025-11-30

### HIGH-10: No TLS/SSL Support
- [ ] Add TLS configuration to dashboard
- [ ] Document reverse proxy setup
- [ ] Add example nginx/traefik configs
- [ ] Update security documentation
- **Assigned to:** Dashboard Team
- **Target:** 2025-12-02

### HIGH-11: Unpinned Action Versions
- [ ] Pin all GitHub Actions to specific versions
- [ ] Update `security-scan.yml`
- [ ] Update `build.yml`
- [ ] Update `release.yml`
- **Assigned to:** CI/CD Team
- **Target:** 2025-11-29

### HIGH-12: Missing Notification Error Tracking
- [ ] Add error counter to notification system
- [ ] Expose errors via `show/notify`
- [ ] Add error metrics
- [ ] Document error monitoring
- **Assigned to:** Notifications Team
- **Target:** 2025-12-01

---

## Testing Checklist

### Integration Testing
- [ ] Fresh clone and `docker compose up -d` works
- [ ] All three compose files work together
- [ ] Metrics endpoint returns data
- [ ] Prometheus scrapes successfully
- [ ] Grafana displays dashboards
- [ ] Dashboard loads and shows spots
- [ ] Notifications can be configured
- [ ] Helm chart deploys to test cluster

### Security Testing
- [ ] Trivy scan shows no CRITICAL
- [ ] Trivy scan shows < 10 HIGH
- [ ] No default credentials
- [ ] Secrets not in git
- [ ] CORS properly configured
- [ ] Rate limiting works

### Functionality Testing
- [ ] Metrics show accurate data
- [ ] Dashboard updates in real-time
- [ ] Notifications filter correctly
- [ ] All ports are accessible
- [ ] Health checks pass

---

## Documentation Checklist

- [ ] README.md updated with Phase 4 features
- [ ] Multi-compose usage documented
- [ ] Environment variables documented
- [ ] Security setup documented
- [ ] Troubleshooting guide updated
- [ ] Architecture diagram created
- [ ] API documentation complete

---

## Review Milestones

### Milestone 1: CRITICAL Fixes (Target: 2025-11-29)
- [ ] All CRITICAL issues resolved
- [ ] Basic integration test passes
- [ ] Security re-scan requested

### Milestone 2: HIGH Fixes (Target: 2025-12-01)
- [ ] At least 10/12 HIGH issues resolved
- [ ] Full integration test suite passes
- [ ] Documentation review complete

### Milestone 3: Final Review (Target: 2025-12-04)
- [ ] All fixes validated
- [ ] QA re-review requested
- [ ] Release candidate tagged

---

## Sign-off

### Team Leads
- [ ] **Metrics Team Lead:** _________________ Date: _______
- [ ] **Dashboard Team Lead:** _________________ Date: _______
- [ ] **Notifications Team Lead:** _________________ Date: _______
- [ ] **Helm Team Lead:** _________________ Date: _______
- [ ] **CI/CD Team Lead:** _________________ Date: _______

### QA Team
- [ ] **QA Lead:** _________________ Date: _______
- [ ] **Security Lead:** _________________ Date: _______

### Final Approval
- [ ] **Project Lead:** _________________ Date: _______

---

## Notes & Blockers

Use this section to track any blockers or dependencies:

```
[Date] [Team] [Issue]
Example:
2025-11-28 Dashboard Waiting for network config decision from Architecture team
```

---

## Quick Commands for Testing

```bash
# Clean environment
docker compose down -v
rm -rf local_data/*

# Fresh start with all features
docker compose -f docker-compose.yml \
               -f metrics/docker-compose.metrics.yml \
               -f dashboard/docker-compose.dashboard.yml \
               up -d --build

# Check all services
docker compose ps

# Test metrics endpoint
curl http://localhost:9100/metrics

# Test dashboard
curl http://localhost:8080/api/health

# Check logs
docker compose logs -f

# Security scan
docker compose down
docker build -t dxspider:test .
trivy image --severity HIGH,CRITICAL dxspider:test
```

---

Last Updated: 2025-11-27
Next Review: 2025-12-04
