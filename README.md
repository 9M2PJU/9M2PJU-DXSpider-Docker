# 9M2PJU-DXSpider-Docker: Elevate Your DXing Experience 🚀

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue)](https://www.docker.com/)
[![DXSpider](https://img.shields.io/badge/DXSpider-Cluster-red)](http://www.dxcluster.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/9M2PJU/9M2PJU-DXSpider-Docker?style=social)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/9M2PJU/9M2PJU-DXSpider-Docker?style=social)](https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/network/members)

**Unleash the Power of DXSpider with Effortless Docker Deployment!**

This project provides a pre-configured, Dockerized DXSpider Cluster Node, empowering amateur radio operators to seamlessly deploy and manage their DXCluster systems.  DXSpider, the gold standard in DX Cluster software, facilitates real-time DX spotting and fosters global communication within the ham radio community.  Say goodbye to complex installations and hello to streamlined DXing!

## ✨ Key Features & Benefits

* **Effortless Deployment:**  Spin up your DXSpider node in minutes with Docker. No more wrestling with dependencies or configurations.
* **Simplified Configuration:**  Customize your setup using a simple `.env` file.  Tailor your cluster to your specific needs with ease.
* **Persistent Data:**  Your valuable configuration and logs are safely stored, ensuring your setup survives container restarts and updates.
* **Scalable & Lightweight:**  Deploy on anything from a Raspberry Pi to a powerful server.  Our optimized Docker image ensures efficient resource usage.
* **Cross-Platform Compatibility:** Docker's magic allows you to run your DXSpider node on various operating systems.
* **Community Driven:**  We encourage contributions and feedback to make this the best DXSpider Docker image available.

## 🛠️ Installation: Get Started in 3 Easy Steps

### 1. Prerequisites

Before you begin, ensure you have the following installed:

* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

### 2. Clone & Configure

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/9M2PJU/9M2PJU-DXSpider-Docker.git
cd 9M2PJU-DXSpider-Docker
```

### 2️⃣ Edit `.env` File
Edit `.env` file in the root directory and configure your DXSpider settings:
```bash
nano .env
```

## 🛠 Configuration
- Modify `startup` or `crontab` to customize settings.
- Add partner link files to `connect` directory.

### 3️⃣ Start the DXSpider Container
```bash
docker compose up -d --build
```

### 4️⃣ Check Logs
To verify that DXSpider is running correctly:
```bash
docker compose logs -f
```

## 📡 Usage
- Connect to the cluster using any DX Cluster client (e.g., **N1MM, DXTelnet, CC Cluster, Log4OM**):
  ```
  telnet your_server_ip 7300
  ```
- Commands can be issued via the DX Cluster interface.

## 🔄 Updating
To update your DXSpider container:
```bash
docker compose down
```
Then rebuild the container:
```bash
docker compose up -d --build
```

## 🤝 Contributing
Pull requests are welcome! If you find a bug or have an improvement, feel free to contribute.

## 📧 Contact
**Author:** 9M2PJU  
**Website:** [hamradio.my](https://hamradio.my)  
**GitHub:** [9M2PJU](https://github.com/9M2PJU)  

---
Happy DXing! 🎙️

