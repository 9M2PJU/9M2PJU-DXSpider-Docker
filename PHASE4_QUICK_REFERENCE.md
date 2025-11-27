# Phase 4 QA - Quick Reference Card

**Print this page for quick reference during fixes**

---

## 🚨 SHOW STOPPERS (Fix These First!)

| # | Issue | File | Line | Fix |
|---|-------|------|------|-----|
| 1 | CORS wildcard | `dashboard/server/dashboard.pl` | 58 | Change `*` to specific origin |
| 2 | Default creds | `metrics/docker-compose.metrics.yml` | 102 | Require password |
| 3 | Network config | `dashboard/docker-compose.dashboard.yml` | 92 | Change to `external: false` |
| 4 | Volume paths | `dashboard/docker-compose.dashboard.yml` | 42 | Fix relative paths |
| 5 | Missing metrics | `Dockerfile` | - | Add `COPY metrics/` |

---

## 🔧 Quick Fixes

### Fix CRIT-01 (CORS)
```perl
# dashboard/server/dashboard.pl:58
# BEFORE:
$c->res->headers->header('Access-Control-Allow-Origin' => '*');

# AFTER:
my $allowed = $ENV{DASHBOARD_ALLOWED_ORIGIN} || 'http://localhost:8080';
$c->res->headers->header('Access-Control-Allow-Origin' => $allowed);
```

### Fix CRIT-02 (Password)
```yaml
# metrics/docker-compose.metrics.yml:102
# BEFORE:
- GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD:-admin}

# AFTER:
- GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD:?ERROR: Set GF_ADMIN_PASSWORD}
```

### Fix CRIT-03 (Network)
```yaml
# dashboard/docker-compose.dashboard.yml:92-94
# BEFORE:
networks:
  dxspider-net:
    external: true
    name: 9m2pju-dxspider-docker_dxspider-net

# AFTER:
networks:
  dxspider-net:
    external: false
```

### Fix CRIT-04 (Volumes)
```yaml
# dashboard/docker-compose.dashboard.yml:42-52
# BEFORE (if running from dashboard/):
volumes:
  - ./dashboard/server:/dashboard/server:ro

# AFTER:
volumes:
  - ./server:/dashboard/server:ro
  - ../local_data:/spider/local_data:ro

# OR document: Must run from project root
```

### Fix CRIT-05 (Metrics)
```dockerfile
# Add to Dockerfile after DXSpider installation:
COPY metrics/prometheus/metrics_server.pl ${SPIDER_INSTALL_DIR}/metrics/
```

### Fix HIGH-04 (Perl Deps)
```dockerfile
# Add to Dockerfile in apk add section:
RUN apk add --no-cache \
    perl \
    # ... existing packages ...
    perl-yaml-libyaml \
    perl-http-tiny \
    perl-json \
    perl-uri \
    perl-io-socket-ssl
```

---

## 📋 Test Commands

```bash
# Quick test after fixes
docker compose down -v
docker compose up -d --build
docker compose ps  # All should be "Up (healthy)"

# Test metrics
curl -s http://localhost:9100/metrics | head -20

# Test dashboard
curl -s http://localhost:8080/api/health

# Test Prometheus scrape
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets'

# Security scan
trivy image --severity CRITICAL,HIGH $(docker images -q | head -1)
```

---

## 🎯 Success Criteria

Before requesting re-review:

✅ All services start: `docker compose ps` shows healthy
✅ Metrics endpoint works: `curl localhost:9100/metrics`
✅ Dashboard loads: `curl localhost:8080`
✅ No default passwords in configs
✅ Security scan passes: No CRITICAL, < 10 HIGH
✅ Fresh install works: Clean clone → up → healthy

---

## 📞 Who to Ask

| Component | Contact |
|-----------|---------|
| Dashboard CORS, volumes, network | Dashboard Team |
| Metrics, Prometheus, Grafana | Metrics Team |
| Notifications, Perl deps | Notifications Team |
| Helm charts | Helm Team |
| GitHub Actions | CI/CD Team |

---

## 🚀 Deployment Readiness

| Environment | Status | Notes |
|-------------|--------|-------|
| Production | 🔴 BLOCKED | Critical issues |
| Staging | 🟡 CAUTION | Manual config needed |
| Development | 🟢 OK | Good for testing |

---

## 📊 Issue Summary

**Total:** 40 issues
**Critical:** 5 (Must fix)
**High:** 12 (Should fix)
**Medium:** 15 (Nice to have)
**Low:** 8 (Minor)

**Current Grade:** D+ (Not ready)
**Target Grade:** B+ (Production ready)

---

## ⏱️ Estimated Time

| Phase | Duration | Target Date |
|-------|----------|-------------|
| Critical fixes | 1-2 days | 2025-11-29 |
| High priority | 2-3 days | 2025-12-01 |
| Testing | 1 day | 2025-12-02 |
| Documentation | 1 day | 2025-12-03 |
| **TOTAL** | **5-7 days** | **2025-12-04** |

---

## 🔗 Related Documents

- **Full Report:** `PHASE4_QA_REPORT.md` - Detailed analysis
- **Summary:** `PHASE4_QA_SUMMARY.md` - Executive summary
- **Checklist:** `PHASE4_FIX_CHECKLIST.md` - Track progress

---

## 💡 Pro Tips

1. **Fix critical issues first** - They're blockers
2. **Test after each fix** - Don't batch and pray
3. **Update checklist** - Track your progress
4. **Read full report** - Context matters
5. **Ask for help** - Coordinate with other teams

---

## ⚠️ Common Mistakes

❌ Fixing HIGH before CRITICAL
❌ Not testing integrations
❌ Forgetting to update docs
❌ Using same passwords in examples
❌ Hardcoding values instead of env vars

---

## ✅ Definition of Done

For each issue:
1. Code changed
2. Tested locally
3. Integration test passes
4. Documentation updated
5. Checklist item marked
6. Peer reviewed
7. Security re-scan (if security issue)

---

**Version:** 1.0
**Last Updated:** 2025-11-27
**Next Review:** 2025-12-04

**Questions?** Check full report or contact QA team
