# Contributing to 9M2PJU-DXSpider-Docker

Thank you for your interest in contributing to this project! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

This project follows the amateur radio tradition of mutual respect and cooperation. Please:

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn
- Keep discussions on-topic
- Remember: 73 (best regards) to all!

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/9M2PJU-DXSpider-Docker.git
   cd 9M2PJU-DXSpider-Docker
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
   ```

## How to Contribute

### Areas Where Help is Needed

- **Documentation**: Improve guides, add examples, fix typos
- **Testing**: Test on different platforms (ARM, x86), report issues
- **Features**: See [ROADMAP.md](ROADMAP.md) for planned features
- **Bug fixes**: Check the issues for bugs to fix
- **Translations**: Help translate documentation

### Quick Contributions

For small changes (typos, minor fixes):
1. Edit the file directly on GitHub
2. Create a pull request with a clear description

### Larger Contributions

For bigger changes:
1. Open an issue first to discuss the change
2. Fork and create a feature branch
3. Make your changes
4. Submit a pull request

## Development Setup

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- Git
- A text editor (VS Code, vim, etc.)

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/9M2PJU-DXSpider-Docker.git
cd 9M2PJU-DXSpider-Docker

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Build and run
docker compose up -d --build

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Testing Changes

```bash
# Rebuild after changes
docker compose down
docker compose up -d --build

# Test telnet connection
telnet localhost 7300

# Test web console
# Open http://localhost:8050 in browser

# Check container health
docker compose ps
docker inspect --format='{{.State.Health.Status}}' 9m2pju-dxspider-docker-dxspider-1
```

## Pull Request Process

### Before Submitting

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes** thoroughly

3. **Update documentation** if needed

4. **Follow style guidelines** (see below)

### Submitting a PR

1. Push your changes to your fork
2. Create a pull request against `main`
3. Fill out the PR template:
   - Clear description of changes
   - Why the change is needed
   - How to test
   - Screenshots if applicable

### PR Review Process

- Maintainers will review within a few days
- Address any requested changes
- Once approved, your PR will be merged

## Style Guidelines

### Shell Scripts (entrypoint.sh, etc.)

```bash
#!/bin/sh
# Use POSIX-compatible shell syntax

# Use meaningful variable names
CLUSTER_PORT=${CLUSTER_PORT:-7300}

# Add comments for complex logic
# Check if cluster is running before proceeding
if ! nc -z localhost ${CLUSTER_PORT}; then
    echo "ERROR: Cluster not running"
    exit 1
fi

# Use consistent indentation (4 spaces)
if [ condition ]; then
    do_something
fi
```

### Dockerfile

```dockerfile
# Use specific versions
FROM alpine:3.20

# Group related commands
RUN apk update && apk add --no-cache \
    package1 \
    package2 \
    package3

# Add comments for non-obvious steps
# Install Perl modules that need compilation
RUN cpanm Module::Name

# Use ARG for build-time variables
ARG SPIDER_VERSION=mojo

# Use ENV for runtime variables
ENV CLUSTER_PORT=7300
```

### docker-compose.yml

```yaml
# Use consistent indentation (2 spaces)
services:
  service_name:
    image: image:tag

    # Group related settings
    environment:
      - VAR1=value1
      - VAR2=value2

    # Add comments for clarity
    # Resource limits for production
    deploy:
      resources:
        limits:
          memory: 512M
```

### Markdown Documentation

- Use ATX-style headers (`#`, `##`, etc.)
- Add blank lines between sections
- Use fenced code blocks with language hints
- Keep lines under 100 characters when possible
- Use relative links for internal references

## Reporting Bugs

### Before Reporting

1. Check existing issues for duplicates
2. Try the latest version
3. Gather relevant information:
   - Docker version (`docker --version`)
   - OS and architecture
   - `.env` configuration (remove passwords!)
   - Error messages and logs

### Bug Report Template

```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Step one
2. Step two
3. ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Docker: [e.g., 24.0.5]
- Architecture: [e.g., amd64, arm64]

**Logs**
```
Paste relevant logs here
```

**Additional Context**
Any other information
```

## Requesting Features

### Before Requesting

1. Check [ROADMAP.md](ROADMAP.md) - it might be planned
2. Search existing issues for similar requests
3. Consider if it fits the project scope

### Feature Request Template

```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why this feature would be useful

**Proposed Solution**
How you think it could be implemented

**Alternatives Considered**
Other approaches you've thought about

**Additional Context**
Any other information, mockups, etc.
```

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes for significant contributions

## Questions?

- Open an issue with the `question` label
- Check existing documentation
- Review closed issues for similar questions

---

Thank you for contributing! 73 de 9M2PJU
