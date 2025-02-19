# 9M2PJU-DXSpider-Docker

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue)](https://www.docker.com/)
[![DXSpider](https://img.shields.io/badge/DXSpider-Cluster-red)](http://www.dxcluster.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 📌 About
This project provides a **Dockerized DXSpider Cluster Node**, allowing amateur radio operators to easily deploy and run a DXCluster system. DXSpider is a widely used DX Cluster software that facilitates real-time DX spotting and communication among ham radio operators worldwide.

## 🚀 Features
- **Containerized Deployment:** Easily deploy DXSpider using Docker.
- **Automatic Configuration:** Uses `.env` file for easy setup.
- **Persistent Data Storage:** Ensures configuration and logs are saved.
- **Lightweight and Scalable:** Can be deployed on a Raspberry Pi, VPS, or dedicated server.

## 📦 Installation

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

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
- Modify `dxspider/startup` or `dxspider/crontab` to customize settings.
- Add partner link files to `dxspider/connect` directory.
- Ports can be mapped in `docker-compose.yml` to suit your network.

### 3️⃣ Start the DXSpider Container
```bash
docker compose up -d
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
docker compose up --build -d
```

## 🤝 Contributing
Pull requests are welcome! If you find a bug or have an improvement, feel free to contribute.

## 📧 Contact
**Author:** 9M2PJU  
**Website:** [hamradio.my](https://hamradio.my)  
**GitHub:** [9M2PJU](https://github.com/9M2PJU)  

---
Happy DXing! 🎙️

