# Changelog

All notable changes to the DXSpider Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-27

### Added
- Initial release of DXSpider Helm chart
- StatefulSet-based deployment for stable network identity
- Comprehensive values.yaml with all configuration options
- Production-ready values-production.yaml
- ConfigMap for startup, crontab, and MOTD configuration
- Secret management for sysop and database passwords
- Service with telnet, console, and metrics ports
- Ingress support for nginx and traefik
- ServiceMonitor for Prometheus Operator integration
- Health checks (liveness, readiness, startup probes)
- Resource limits and requests configuration
- Persistent storage with volumeClaimTemplates
- Security contexts (non-root, read-only filesystem where possible)
- Template helpers for common functions
- Comprehensive NOTES.txt with post-installation instructions
- Complete README.md documentation
- Installation guide (INSTALL.md)
- Changelog (CHANGELOG.md)
- .helmignore for package optimization

### Features
- Support for Kubernetes 1.23+
- Helm 3.x compatibility
- Multiple service types (ClusterIP, NodePort, LoadBalancer)
- Configurable partner node connections
- Database support (optional MariaDB integration)
- Auto-generated sysop password if not provided
- Callsign and locator uppercase normalization
- Flexible resource management
- Node affinity and tolerations support
- Priority class support
- Additional init containers and sidecars support
- Extra environment variables support
- Custom volumes and volume mounts

### Configuration
- Cluster configuration (callsign, location, QTH)
- Sysop configuration (name, callsign, email)
- Network configuration (ports, hostname)
- Persistence configuration (storage class, size)
- Metrics and monitoring configuration
- Ingress configuration with TLS support
- Health check configuration
- Resource limits and requests

### Documentation
- Comprehensive README with examples
- Architecture diagrams
- Troubleshooting guide
- Upgrade and rollback procedures
- Configuration reference
- Quick installation guide

## [Unreleased]

### Planned
- Horizontal Pod Autoscaler (HPA) support for metrics
- Network policies for enhanced security
- Pod Disruption Budget (PDB) for high availability
- Backup and restore procedures
- Helm chart repository publication
- Example Terraform/Ansible integration
- Monitoring dashboards (Grafana)
- Alert rules (Prometheus)

---

**Note**: This is the first stable release of the DXSpider Helm chart. Future releases will follow semantic versioning:
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes
