# CI/CD Pipeline Documentation

This document describes the CI/CD pipeline for the 9M2PJU-DXSpider-Docker project.

## Overview

The CI/CD pipeline consists of three main workflows and automated dependency management:

1. **Build and Test** (`build.yml`) - Runs on every push and PR
2. **Security Scan** (`security-scan.yml`) - Runs on push, PR, and weekly schedule
3. **Release** (`release.yml`) - Runs on GitHub releases
4. **Dependabot** (`dependabot.yml`) - Automated dependency updates

## Workflows

### 1. Build and Test (`build.yml`)

**Triggers:**
- Push to `main`, `master`, or `develop` branches
- Pull requests to `main`, `master`, or `develop` branches
- Manual workflow dispatch

**Jobs:**

#### Build Job
- Sets up QEMU for multi-architecture builds
- Configures Docker Buildx for efficient building
- Builds for `linux/amd64` and `linux/arm64` platforms
- Caches Docker layers using GitHub Actions cache
- Builds both `mojo` and `master` DXSpider variants
- Runs comprehensive smoke tests
- Uploads build artifacts and logs

**Caching Strategy:**
- Docker layer caching reduces build times by 50-70%
- Cache key: `${{ runner.os }}-buildx-${{ github.sha }}`
- Restore keys ensure previous builds are leveraged

#### Lint Job
- Runs [hadolint](https://github.com/hadolint/hadolint) on Dockerfile
- Checks for best practices and common mistakes
- Configurable failure threshold (currently: warning)
- Ignores: DL3018 (Alpine package pinning), DL3013 (pip pinning)

#### ShellCheck Job
- Validates all shell scripts in `scripts/` directory
- Checks `entrypoint.sh` for common shell scripting errors
- Minimum severity: warning

#### Summary Job
- Aggregates results from all jobs
- Provides clear pass/fail status
- Runs even if individual jobs fail

**Usage:**
```bash
# Automatically runs on push/PR
# Or manually trigger:
gh workflow run build.yml
```

### 2. Security Scan (`security-scan.yml`)

**Triggers:**
- Push to main branches
- Pull requests
- Weekly schedule (Mondays at 06:00 UTC)
- Manual workflow dispatch

**Jobs:**

#### Trivy Vulnerability Scan
- Scans container images for vulnerabilities
- Checks OS packages and libraries
- Severity levels: CRITICAL, HIGH, MEDIUM
- Uploads results to GitHub Security tab (SARIF format)
- **Failure threshold:** Critical vulnerabilities > 0 OR High vulnerabilities > 10
- Generates JSON report for detailed analysis

**SARIF Integration:**
- Results appear in GitHub Security > Code scanning alerts
- Enables dependency graph and security advisories
- Provides actionable remediation advice

#### Dockerfile Security Scan
- Scans Dockerfile for misconfigurations
- Checks for hardcoded secrets
- Validates security best practices
- Results uploaded to Security tab

#### Secret Scanning
- Uses [Gitleaks](https://github.com/gitleaks/gitleaks) to detect secrets
- Scans entire git history
- Prevents accidental credential commits
- Fails build if secrets are detected

#### Dependency Review (PR only)
- Reviews new dependencies in pull requests
- Fails on moderate or higher severity vulnerabilities
- Blocks GPL-3.0 and AGPL-3.0 licenses (configurable)

**Usage:**
```bash
# View security alerts
# GitHub > Security > Code scanning

# Run manually
gh workflow run security-scan.yml

# View Trivy results locally
gh run view <run-id> --log
```

### 3. Release (`release.yml`)

**Triggers:**
- GitHub release publication
- Manual workflow dispatch with tag input

**Jobs:**

#### Release Job
- Builds multi-arch images for both `mojo` and `master` variants
- Publishes to GitHub Container Registry (GHCR)
- Optional: Publishes to Docker Hub (requires secrets)
- Creates semantic version tags
- Generates SBOM (Software Bill of Materials)
- Includes SLSA provenance for supply chain security

**Image Tags Created:**
```
ghcr.io/9m2pju/9m2pju-dxspider-docker:latest
ghcr.io/9m2pju/9m2pju-dxspider-docker:1.2.3
ghcr.io/9m2pju/9m2pju-dxspider-docker:1.2
ghcr.io/9m2pju/9m2pju-dxspider-docker:1
ghcr.io/9m2pju/9m2pju-dxspider-docker:abc1234 (git SHA)
ghcr.io/9m2pju/9m2pju-dxspider-docker:mojo
ghcr.io/9m2pju/9m2pju-dxspider-docker:master
ghcr.io/9m2pju/9m2pju-dxspider-docker:1.2.3-master
```

**Release Notes:**
- Automatically generated with image pull commands
- Includes verified image digests
- Lists supported architectures
- Provides quick start guide
- Attaches SBOM as release asset

#### Test Release Job
- Pulls and tests published images
- Verifies both `mojo` and `master` variants
- Runs basic smoke tests
- Validates image metadata

**Usage:**
```bash
# Create a release
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 --generate-notes

# Or manually trigger
gh workflow run release.yml -f tag=v1.0.0

# Pull released image
docker pull ghcr.io/9m2pju/9m2pju-dxspider-docker:latest
```

### 4. Dependabot (`dependabot.yml`)

**Automated Updates:**
- GitHub Actions dependencies (weekly, Mondays 06:00 UTC)
- Docker base images (weekly, Mondays 06:00 UTC)

**Configuration:**
- Maximum 5 open PRs per ecosystem
- Automatic labeling for easy filtering
- Commit message prefixes: `ci:` (actions), `docker:` (images)
- Auto-assign to repository maintainers

**Ignored Updates:**
- Alpine major version updates (manual review required)
- MariaDB major version updates (manual review required)

**Usage:**
```bash
# View Dependabot PRs
gh pr list --label dependencies

# Enable/disable in repo settings
# Settings > Security > Dependabot
```

## Smoke Test Script

**Location:** `scripts/smoke-test.sh`

**What it tests:**
- Container starts successfully
- Health check passes
- DXSpider process is running
- Configuration files are generated
- Telnet port (7300) is accessible
- Web console port (8050) is accessible
- Log files are created
- Basic telnet interaction works

**Usage:**
```bash
# Run locally
./scripts/smoke-test.sh

# Run with custom image
IMAGE_NAME=myimage:latest ./scripts/smoke-test.sh

# Check logs
cat /tmp/test-smoke-*.log
```

**Exit codes:**
- `0` - All tests passed
- `1` - One or more tests failed

## Required Secrets

Configure these in GitHub Settings > Secrets:

### Required for Release to GHCR
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### Optional for Docker Hub
- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token

### Optional for Gitleaks
- `GITLEAKS_LICENSE` - Gitleaks Pro license (if using)

## Setting Up Secrets

```bash
# Add Docker Hub credentials (optional)
gh secret set DOCKERHUB_USERNAME -b "your-username"
gh secret set DOCKERHUB_TOKEN -b "your-token"

# GITHUB_TOKEN is automatically available
```

## Permissions

The workflows require the following permissions:

### Build Workflow
- `contents: read`
- `packages: write` (if pushing to GHCR)

### Security Workflow
- `contents: read`
- `security-events: write`
- `actions: read`

### Release Workflow
- `contents: write`
- `packages: write`
- `id-token: write` (for SLSA provenance)

## GitHub Pages Integration (Optional)

To publish build badges and status pages:

1. Enable GitHub Pages in repository settings
2. Add status badge to README.md:

```markdown
[![Build Status](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/build.yml)
[![Security Scan](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml/badge.svg)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/actions/workflows/security-scan.yml)
```

## Troubleshooting

### Build Failures

**Issue:** Multi-arch build fails
```bash
# Check QEMU setup
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify buildx
docker buildx ls
```

**Issue:** Cache not working
```bash
# Clear GitHub Actions cache
gh cache delete <cache-key>

# Or delete all caches
gh cache list | awk '{print $1}' | xargs -I {} gh cache delete {}
```

### Security Scan Failures

**Issue:** Too many vulnerabilities
- Check Trivy results in Security tab
- Update base image version
- Review Alpine package updates
- Consider using distroless images for runtime

**Issue:** False positives
- Add to `.trivyignore` file
- Adjust severity threshold in workflow

### Release Failures

**Issue:** Tag already exists
```bash
# Delete local and remote tag
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# Create new release
git tag v1.0.0
git push origin v1.0.0
```

**Issue:** GHCR push denied
- Check `GITHUB_TOKEN` permissions
- Verify package visibility settings
- Enable "Read and write permissions" in Settings > Actions

## Performance Optimization

### Build Time Optimization
- Layer caching reduces build time by 50-70%
- Parallel multi-arch builds
- Efficient cache key strategy

### Current Build Times
- Initial build: ~5-8 minutes
- Cached build: ~2-3 minutes
- Multi-arch build: ~4-6 minutes

### Tips for Faster Builds
1. Use cache-from and cache-to
2. Order Dockerfile layers from least to most frequently changed
3. Combine RUN commands to reduce layers
4. Use `.dockerignore` to exclude unnecessary files

## Monitoring and Alerts

### GitHub Actions Notifications
- Configure in Settings > Notifications
- Email alerts for workflow failures
- Slack/Discord integration available

### Dependabot Alerts
- Settings > Security > Dependabot alerts
- Email notifications for new vulnerabilities
- Auto-triage with security policies

## Best Practices

1. **Always run smoke tests locally** before pushing
2. **Review security scan results** before merging PRs
3. **Keep dependencies updated** via Dependabot
4. **Use semantic versioning** for releases
5. **Document breaking changes** in release notes
6. **Monitor build times** and optimize when needed
7. **Review and merge Dependabot PRs** regularly

## Maintenance

### Weekly Tasks
- Review Dependabot PRs
- Check security scan results
- Monitor build performance

### Monthly Tasks
- Review and update workflow versions
- Audit security alerts
- Update documentation

### Quarterly Tasks
- Evaluate new GitHub Actions features
- Review caching strategy
- Update base images

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [SLSA Framework](https://slsa.dev/)

## Support

For issues with the CI/CD pipeline:
1. Check workflow run logs in Actions tab
2. Review this documentation
3. Open an issue with workflow run link
4. Contact maintainers via GitHub Discussions
