<div align="center">

# 🌐 9M2PJU-DXSpider-Docker

### Revolutionizing Amateur Radio DX Clustering with Docker

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![DXSpider](https://img.shields.io/badge/DXSpider-FF4B4B?style=for-the-badge&logo=radio&logoColor=white)](http://www.dxcluster.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/9M2PJU/9M2PJU-DXSpider-Docker?style=for-the-badge)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/9M2PJU/9M2PJU-DXSpider-Docker?style=for-the-badge)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/network/members)

*Transforming DXSpider deployment into a seamless Docker experience for the global amateur radio community* 📡

[Key Features](#-key-features) • [Quick Start](#-quick-start) • [Installation](#%EF%B8%8F-installation) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

<div align="center">
  <h1>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Radio.png" alt="Radio" width="25" height="25" />
    Special Acknowledgment
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Satellite%20Antenna.png" alt="Satellite" width="25" height="25" />
  </h1>
</div>

<div align="center">
  <img src="https://img.shields.io/badge/DXSpider-Creator-blue?style=for-the-badge" alt="DXSpider Creator"/>
  <img src="https://img.shields.io/badge/G1TLH-Amateur%20Radio-red?style=for-the-badge" alt="G1TLH"/>
</div>

<br>

<div align="center">
  <table>
    <tr>
      <td align="center">
        <h3>📡 Thank You Dirk Koopman (G1TLH)</h3>
        <p>We extend our deepest gratitude to <b>Dirk Koopman (G1TLH)</b> for creating <b>DXSpider</b>, 
        a revolutionary contribution that transformed DX Cluster networking.</p>
        <p>His innovative work continues to empower the global amateur radio community.</p>
      </td>
    </tr>
  </table>
</div>

<div align="center">
  <h4>🌟 Key Impacts</h4>
  <code>Real-time DX Information</code> •
  <code>Global Communications</code> •
  <code>Community Building</code>
</div>

<br>

<div align="center">
  <i>"Standing on the shoulders of giants - The continued evolution of DX clustering 
  owes much to G1TLH's pioneering vision."</i>
</div>

<hr>

## 📡 Overview

9M2PJU-DXSpider-Docker revolutionizes the way amateur radio operators deploy and manage DX Cluster nodes. By containerizing the legendary DXSpider cluster software, we've eliminated complex setup procedures while maintaining all the powerful features that make DXSpider the gold standard in DX clustering.

### Why Choose This Solution?

- 🚀 **Minimal-Configuration Deployment** - Up and running in minutes
- 🔒 **Security First** - Hardened container configuration
- 🔄 **Easy Updates** - Stay current with ease
- 🌍 **Global Community** - Join a worldwide network of operators

## ✨ Key Features

### Core Capabilities

- **🐳 Docker-Native Architecture**
  - Optimized multi-stage builds
  - Minimal base image for reduced attack surface
  - Environment-based configuration

- **🔧 Intelligent Defaults**
  - Pre-configured for optimal performance
  - Smart scaling based on available resources
  - Automatic port management

## 🛠️ Installation

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git

# Navigate to the directory
cd 9M2PJU-DXSpider-Docker
```

### Step-by-Step Guide

1. **Environment Setup**
   ```bash
   nano .env  # Configure your settings
   ```
2. **Cron, startup**
   ```bash
   nano startup  # Configure your startup
   nano crontab # Configure cron
   ```
3. **Partner links**
   ```bash
   touch connect/9m2pju-2
   nano connect/9m2pju-2
   ```

3. **Container Deployment**
   ```bash
   docker compose up -d --build
   ```

4. **Verify Installation**
   ```bash
   docker compose logs -f
   ```

## 📚 Documentation

### Connection Details

Connect using any DX Cluster client:
```
Host: your_server_ip
Port: 7300
```

### Supported Clients

- ✅ N1MM Logger+
- ✅ DXTelnet
- ✅ CC Cluster
- ✅ Log4OM
- ✅ Any Telnet-capable client

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `DX_CALLSIGN` | Your node callsign | `9M2PJU-10` |
| `DX_PORT` | Listening port | `7300` |

## 🔄 Updates & Maintenance

### Updating the Container

```bash
# Rebuild and restart
docker compose down
docker compose up -d --build
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

## 🌟 Support the Project

If you find this project useful, please consider:

- ⭐ Starring the repository
- 🔀 Forking and contributing
- 📢 Sharing with other operators

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### Made with ❤️ by the Amateur Radio Community

*73 de 9M2PJU* 📡

</div>
