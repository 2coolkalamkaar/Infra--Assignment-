

## 📋 Project Overview
This project deploys a highly available, scalable, and observable **WordPress** application stack on Kubernetes. It demonstrates advanced DevOps practices including **Helm Chart management**, **Custom Docker Builds**, **Prometheus Monitoring**, and **Auto-Scaling (HPA)**.

### 🏗️ Architecture
* **Frontend/Proxy:** Custom-built Nginx (OpenResty) with Lua support & Sidecar Exporter.
* **Application:** WordPress (StatefulSet/Deployment) with HPA enabled.
* **Database:** MySQL 5.7 with Persistent Storage.
* **Observability:** Prometheus Operator stack with ServiceMonitors and Custom Alerts.

---

## 🛠️ Directory Structure
```text
assignment/
├── docker/             # Custom Dockerfiles (Nginx OpenResty build)
├── helm/               # Custom Helm Chart (wordpress-stack)
└── scripts/            # Automation Tools (Traffic gen, Reset scripts)