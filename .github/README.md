# GitHub Workflows

This directory contains the CI/CD pipeline configuration for the 9M2PJU-DXSpider-Docker project.

## Workflows

### 🔨 [build.yml](workflows/build.yml)
**Main CI Pipeline**

Runs on every push and pull request to build, test, and validate the Docker images.

- Multi-architecture builds (amd64, arm64)
- Docker layer caching
- Smoke tests
- Dockerfile linting (hadolint)
- Shell script validation (ShellCheck)

**Status:** [![Build](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml)

---

### 🔒 [security-scan.yml](workflows/security-scan.yml)
**Security Scanning**

Comprehensive security scanning with Trivy, Gitleaks, and dependency review.

- Container vulnerability scanning
- Dockerfile security analysis
- Secret detection
- Dependency review (PRs only)
- Weekly scheduled scans

**Status:** [![Security](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml)

---

### 🚀 [release.yml](workflows/release.yml)
**Release Publishing**

Builds and publishes Docker images to GitHub Container Registry on release.

- Multi-arch image builds
- Semantic versioning tags
- SBOM generation
- SLSA provenance
- Release notes automation

**Status:** [![Release](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/release.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/release.yml)

---

### 🤖 [dependabot.yml](dependabot.yml)
**Automated Dependency Updates**

Keeps dependencies up-to-date automatically.

- GitHub Actions updates
- Docker base image updates
- Weekly schedule
- Auto-labeling and assignment

---

## Quick Links

- 📖 [Full CI/CD Documentation](CICD.md)
- ⚡ [Quick Reference Guide](CICD-QUICKREF.md)
- 🔐 [Security Alerts](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/security)
- 📦 [Package Registry](https://github.com/9M2PJU/packages)
- 🐛 [Issues](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues)

## Getting Started

### Running Tests Locally

```bash
# Build the image
docker build -t test:latest .

# Run smoke tests
./scripts/smoke-test.sh
```

### Creating a Release

```bash
# Tag the version
git tag v1.0.0

# Push the tag
git push origin v1.0.0

# Create release (triggers release workflow)
gh release create v1.0.0 --generate-notes
```

### Viewing Workflow Runs

```bash
# List recent runs
gh run list

# Watch a run in progress
gh run watch

# View logs
gh run view <run-id> --log
```

## Workflow Triggers

| Workflow | Push | PR | Schedule | Release | Manual |
|----------|------|----|----|---------|--------|
| Build | ✅ | ✅ | ❌ | ❌ | ✅ |
| Security | ✅ | ✅ | ✅ Weekly | ❌ | ✅ |
| Release | ❌ | ❌ | ❌ | ✅ | ✅ |

## Published Images

Images are published to GitHub Container Registry (GHCR):

```bash
# Pull latest
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:latest

# Pull specific version
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:1.0.0

# Pull master variant
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:master
```

### Supported Architectures
- `linux/amd64` - x86_64 / AMD64
- `linux/arm64` - ARM 64-bit (Raspberry Pi 4, Apple Silicon)

## Security

All images are:
- 🔍 Scanned for vulnerabilities with Trivy
- 📋 Include Software Bill of Materials (SBOM)
- ✍️ Signed with SLSA provenance
- 🔒 Built from minimal Alpine Linux base

View security reports in the [Security tab](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/security).

## Contributing

When contributing, ensure:
1. ✅ All CI checks pass
2. 🔒 No security vulnerabilities introduced
3. 📝 Update documentation if needed
4. ✅ Smoke tests pass locally

## Support

- 📖 Read the [CI/CD Documentation](CICD.md)
- ⚡ Check the [Quick Reference](CICD-QUICKREF.md)
- 🐛 [Report Issues](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues)
- 💬 [GitHub Discussions](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/discussions)
