# CI/CD Quick Reference Guide

Quick reference for common CI/CD operations in the 9M2PJU-DXSpider-Docker project.

## Table of Contents
- [Common Commands](#common-commands)
- [Workflows](#workflows)
- [Troubleshooting](#troubleshooting)
- [Cheat Sheet](#cheat-sheet)

---

## Common Commands

### Run Smoke Tests Locally
```bash
# Build image
docker build -t test:latest .

# Run smoke tests
./scripts/smoke-test.sh

# Run with custom configuration
IMAGE_NAME=myimage:latest CLUSTER_PORT=7300 ./scripts/smoke-test.sh
```

### Trigger Workflows Manually
```bash
# Trigger build workflow
gh workflow run build.yml

# Trigger security scan
gh workflow run security-scan.yml

# Trigger release with tag
gh workflow run release.yml -f tag=v1.0.0
```

### View Workflow Status
```bash
# List recent workflow runs
gh run list

# View specific run
gh run view <run-id>

# Watch run in real-time
gh run watch <run-id>

# View logs
gh run view <run-id> --log
```

### Manage Releases
```bash
# Create a new release
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 --generate-notes

# Delete a release
gh release delete v1.0.0
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# View releases
gh release list
gh release view v1.0.0
```

### Pull Released Images
```bash
# Pull latest
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:latest

# Pull specific version
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:1.0.0

# Pull master variant
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:master

# Pull for specific architecture
docker pull --platform linux/arm64 ghcr.io/9m2pju/9m2pju-dxspider-docker:latest
```

---

## Workflows

### Build Workflow Status
```bash
# Check if build is passing
gh workflow view build.yml

# List recent build runs
gh run list --workflow=build.yml

# Re-run failed build
gh run rerun <run-id>
```

### Security Scan Results
```bash
# View security workflow runs
gh run list --workflow=security-scan.yml

# Download Trivy results
gh run download <run-id>

# View in GitHub Security tab
open "https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/security/code-scanning"
```

### Dependabot PRs
```bash
# List Dependabot PRs
gh pr list --label dependencies

# Auto-merge Dependabot PR (if checks pass)
gh pr merge <pr-number> --auto --squash

# Close Dependabot PR
gh pr close <pr-number>
```

---

## Troubleshooting

### Build Failing

**Check build logs:**
```bash
gh run view <run-id> --log
```

**Common fixes:**
```bash
# Clear cache
gh cache delete <cache-key>

# Rebuild without cache
gh workflow run build.yml

# Check Dockerfile syntax
docker build --check .
hadolint Dockerfile
```

### Security Scan Failing

**View vulnerabilities:**
```bash
# Download and view Trivy results
gh run download <run-id>
cat trivy-results.json | jq '.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL")'
```

**Ignore false positives:**
```bash
# Add to .trivyignore
echo "CVE-2024-12345" >> .trivyignore
git add .trivyignore
git commit -m "ci: ignore CVE-2024-12345 - false positive"
```

### Release Failing

**Check permissions:**
```bash
# Verify GITHUB_TOKEN has write access
# Settings > Actions > General > Workflow permissions
# Select "Read and write permissions"
```

**Re-tag release:**
```bash
# Delete old tag
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# Create new tag
git tag v1.0.0
git push origin v1.0.0
```

### Slow Builds

**Check cache usage:**
```bash
# List caches
gh cache list

# View cache size
gh cache list --json | jq '.[].size_in_bytes'
```

**Optimize Dockerfile:**
```dockerfile
# Order layers from least to most frequently changed
# Use multi-stage builds
# Combine RUN commands
# Use .dockerignore
```

---

## Cheat Sheet

### Workflow Triggers

| Workflow | Push | PR | Schedule | Release | Manual |
|----------|------|----|----|---------|--------|
| build.yml | ✅ | ✅ | ❌ | ❌ | ✅ |
| security-scan.yml | ✅ | ✅ | ✅ Weekly | ❌ | ✅ |
| release.yml | ❌ | ❌ | ❌ | ✅ | ✅ |

### Image Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `latest` | Latest mojo build | `ghcr.io/.../dxspider:latest` |
| `mojo` | Latest mojo branch | `ghcr.io/.../dxspider:mojo` |
| `master` | Latest master branch | `ghcr.io/.../dxspider:master` |
| `x.y.z` | Semver version | `ghcr.io/.../dxspider:1.2.3` |
| `x.y` | Minor version | `ghcr.io/.../dxspider:1.2` |
| `x` | Major version | `ghcr.io/.../dxspider:1` |
| `sha` | Git commit SHA | `ghcr.io/.../dxspider:abc1234` |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General failure |
| 2 | Misconfiguration |
| 125 | Docker daemon error |
| 126 | Command cannot be invoked |
| 127 | Command not found |

### Useful GitHub CLI Commands

```bash
# Authentication
gh auth login
gh auth status

# Workflows
gh workflow list
gh workflow view <workflow-name>
gh workflow run <workflow-name>
gh workflow enable <workflow-name>
gh workflow disable <workflow-name>

# Runs
gh run list --workflow=<workflow-name>
gh run view <run-id>
gh run watch <run-id>
gh run rerun <run-id>
gh run cancel <run-id>
gh run download <run-id>

# Secrets
gh secret list
gh secret set <name>
gh secret delete <name>

# Cache
gh cache list
gh cache delete <cache-key>

# Releases
gh release list
gh release view <tag>
gh release create <tag>
gh release delete <tag>
```

### Docker Multi-Arch Commands

```bash
# Setup
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myimage:latest \
  --push .

# Inspect multi-arch manifest
docker buildx imagetools inspect ghcr.io/9m2pju/9m2pju-dxspider-docker:latest

# Build for specific platform
docker buildx build \
  --platform linux/arm64 \
  -t myimage:arm64 \
  --load .
```

### Trivy Commands

```bash
# Scan local image
trivy image dxspider:latest

# Scan with specific severity
trivy image --severity CRITICAL,HIGH dxspider:latest

# Output to SARIF
trivy image --format sarif --output results.sarif dxspider:latest

# Scan Dockerfile
trivy config Dockerfile

# Scan filesystem
trivy fs .

# Update vulnerability database
trivy image --download-db-only
```

---

## Environment Variables

### Build Time
- `SPIDER_VERSION` - DXSpider branch (mojo/master)
- `SPIDER_USERNAME` - System username (default: sysop)
- `SPIDER_UID` - User ID (default: 1000)

### Runtime
- `CLUSTER_CALLSIGN` - Node callsign
- `CLUSTER_PORT` - Telnet port (default: 7300)
- `CLUSTER_SYSOP_PORT` - Web console port (default: 8050)
- `CLUSTER_LOCATOR` - Grid locator
- `CLUSTER_QTH` - Location name
- `CLUSTER_LATITUDE` - Latitude (+/-DD.DD)
- `CLUSTER_LONGITUDE` - Longitude (+/-DDD.DD)

### CI/CD
- `IMAGE_NAME` - Image name for smoke tests
- `PLATFORMS` - Target platforms (linux/amd64,linux/arm64)

---

## Status Badges

Add to README.md:

```markdown
[![Build](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml)
[![Security](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml)
[![Release](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/release.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/release.yml)
```

---

## Quick Links

- [GitHub Actions Logs](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions)
- [Security Alerts](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/security)
- [Dependabot](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/security/dependabot)
- [Package Registry](https://github.com/9M2PJU/packages)
- [Full Documentation](./CICD.md)

---

## Getting Help

1. Check workflow logs: `gh run view <run-id> --log`
2. Review [full CI/CD documentation](./CICD.md)
3. Search existing issues: `gh issue list`
4. Create new issue: `gh issue create`
5. GitHub Discussions for Q&A

---

**Last Updated:** 2025-11-27
