# Hệ thống Monitor và Quản trị VM1

Hệ thống monitor và quản trị cho VM1, có khả năng kết nối và quản lý các Docker containers trên VM2.

## 🏗️ Kiến trúc

### VM1 - Infrastructure/Management (Nhẹ)
- **Portainer**: Quản lý Docker containers
- **Cloudflared**: Tunnel để truy cập từ xa (tùy chọn)
- **cAdvisor**: Container monitoring
- **Node Exporter**: System metrics
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboard
- **Syslog**: Log aggregation
- **Watchtower**: Auto update containers

### VM2 - Application Servers
- **Tailscale**: VPN để kết nối với VM1
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics
- **Docker API Proxy**: Để Portainer quản lý

## 🚀 Cài đặt và Khởi động

### Cách 1: Cài đặt tự động (Khuyến nghị)
```bash
# Clone project
git clone <repository-url>
cd monitor-vm1

# Chạy script cài đặt tự động
chmod +x install.sh
./install.sh

# Hoặc sử dụng Makefile
make quick-start
```

### Cách 2: Cài đặt thủ công
```bash
# 1. Chuẩn bị môi trường
# Ubuntu/Debian:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
# Docker Compose is now included with Docker Desktop and newer Docker installations
# For older systems, install docker compose (legacy):
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker compose
sudo chmod +x /usr/local/bin/docker compose

# 2. Thiết lập bảo mật
cp env.example .env
./monitor setup
./monitor audit

# 3. Khởi động hệ thống
./monitor start
```

### 4. Cấu hình Tailscale
1. Đăng ký tài khoản tại [tailscale.com](https://tailscale.com)
2. Tạo Auth Key trong Tailscale Admin Console
3. Cài đặt Tailscale: `./monitor tailscale`
4. Join VM1 vào Tailscale: `sudo tailscale up`
5. Cập nhật `VM2_TAILSCALE_HOST` trong file `.env`
6. Khởi động hệ thống: `./monitor start`

### 5. Cấu hình Cloudflare Tunnel (Tùy chọn)
1. Đăng nhập Cloudflare Dashboard
2. Tạo tunnel mới
3. Copy token và cập nhật vào file `.env`
4. Khởi động với profile: `docker compose --profile cloudflare up -d`

## 📊 Truy cập Services

| Service | URL | Mô tả |
|---------|-----|-------|
| Portainer | http://localhost:9000 | Quản lý Docker containers |
| Grafana | http://localhost:3000 | Dashboard monitoring |
| Prometheus | http://localhost:9090 | Metrics collection |
| cAdvisor | http://localhost:8080 | Container metrics |
| Node Exporter | http://localhost:9100 | System metrics |

**Mặc định:**
- Grafana: admin/admin123
- Portainer: Tạo tài khoản admin lần đầu

## 🔧 Quản lý Hệ thống

### Scripts có sẵn
```bash
./monitor start       # Khởi động hệ thống
./monitor stop        # Dừng hệ thống
./monitor restart     # Restart hệ thống
./monitor status      # Kiểm tra trạng thái
./monitor setup       # Thiết lập bảo mật và secrets
./monitor audit       # Kiểm tra bảo mật
./monitor demo        # Demo các vấn đề bảo mật
./monitor build       # Build Docker images an toàn
./monitor cleanup     # Xóa hoàn toàn (cẩn thận!)
./monitor vm2         # Thiết lập kết nối VM2
./monitor tailscale   # Cài đặt Tailscale
./monitor backup      # Backup dữ liệu hệ thống
./monitor restore     # Restore dữ liệu hệ thống
./monitor update      # Cập nhật Docker images
./monitor logs        # Xem logs của services
./monitor help        # Hiển thị trợ giúp
```

### Quản lý Docker
```bash
# Xem logs
docker compose logs -f

# Xem trạng thái
./monitor status

# Restart service cụ thể
docker compose restart portainer

# Cập nhật images
docker compose pull
docker compose up -d
```

## 🔗 Kết nối VM2

### 1. Thiết lập VM2
```bash
# Chạy script thiết lập
./monitor vm2

# Làm theo hướng dẫn để cài đặt trên VM2
```

### 2. Cấu hình Portainer
1. Truy cập Portainer: http://localhost:9000
2. Thêm endpoint mới:
   - Name: VM2
   - URL: tcp://VM2_TAILSCALE_HOST:2376
   - Public IP: VM2_TAILSCALE_HOST

### 3. Cấu hình Monitoring
- Prometheus sẽ tự động thu thập metrics từ VM2
- Grafana sẽ hiển thị dashboard cho cả VM1 và VM2

## 📁 Cấu trúc Thư mục

```
monitor-vm1/
├── docker compose.yml          # Stack chính
├── docker compose.override.yml # Override cho development
├── .dockerignore               # Loại trừ file nhạy cảm
├── .gitignore                  # Git ignore rules
├── env.example                 # Template cấu hình
├── Dockerfile.template         # Template Dockerfile an toàn
├── SECURITY.md                 # Hướng dẫn bảo mật
├── config/
│   ├── prometheus.yml         # Cấu hình Prometheus
│   ├── prometheus/
│   │   └── alerts.yml         # Prometheus alerting rules
│   ├── grafana/
│   │   └── provisioning/      # Cấu hình Grafana
│   │       ├── datasources/   # Data sources config
│   │       └── dashboards/    # Dashboard configs
│   └── syslog/
│       └── syslog-ng.conf     # Cấu hình Syslog
├── secrets/                    # Secrets directory (không commit)
│   ├── grafana_password.txt   # Grafana password
│   └── cloudflare_token.txt   # Cloudflare token
├── scripts/
│   └── monitor.sh             # Script quản lý chính (all-in-one)
├── monitor                    # Wrapper script (dễ sử dụng)
└── README.md                  # Tài liệu này
```

## 🔧 Cấu hình Nâng cao

### Environment Variables (.env)
```bash
# Cloudflare Tunnel (Optional)
CLOUDFLARE_TUNNEL_TOKEN=your_token_here

# Grafana
GRAFANA_PASSWORD=admin123

# VM2 Connection via Tailscale
VM2_TAILSCALE_HOST=vm2-hostname
VM2_SSH_PORT=22
VM2_DOCKER_PORT=2376

# Monitoring
PROMETHEUS_RETENTION=200h
GRAFANA_ADMIN_USER=admin
```

### Custom Dashboards
- Thêm dashboard vào `config/grafana/provisioning/dashboards/`
- Restart Grafana để áp dụng

### Alerting
- Cấu hình alerting trong Prometheus (CPU, Memory, Disk, Service Down)
- Tích hợp với Slack, Email, Discord
- Dashboard Grafana với alerts và notifications

### Backup & Restore
```bash
# Backup hệ thống
./monitor backup

# Restore từ backup
./monitor restore monitor_backup_20241201_120000.tar.gz
```

### Makefile Commands
```bash
make help          # Hiển thị tất cả lệnh
make install       # Cài đặt tự động
make start         # Khởi động hệ thống
make stop          # Dừng hệ thống
make status        # Kiểm tra trạng thái
make logs          # Xem logs
make update        # Cập nhật images
make health        # Chạy health checks
make test          # Test hệ thống
```

### Advanced Features
```bash
# Cài đặt dependencies bổ sung
./scripts/install-deps.sh

# Chạy test hệ thống
./scripts/test-system.sh

# Monitor daemon (background monitoring)
./scripts/monitor-daemon.sh start
./scripts/monitor-daemon.sh stop
./scripts/monitor-daemon.sh status
```

## 🐛 Troubleshooting

### Kiểm tra logs
```bash
# Tất cả services
docker compose logs

# Service cụ thể
docker compose logs portainer
docker compose logs prometheus
```

### Kiểm tra kết nối
```bash
# Kiểm tra ports
netstat -tulpn | grep -E ":(3000|8080|9000|9090|9100)"

# Kiểm tra containers
docker ps
```

### Reset hoàn toàn
```bash
./monitor cleanup
./monitor start
```

## 📝 Ghi chú

- Hệ thống được thiết kế để chạy nhẹ trên VM1
- Tất cả dữ liệu được lưu trong Docker volumes
- Watchtower tự động cập nhật containers
- Syslog thu thập logs từ tất cả containers
- **Tailscale**: Các VM giao tiếp với nhau qua Tailscale VPN, không cần mở port ra ngoài
- **Bảo mật**: Chỉ các VM trong cùng Tailscale network mới có thể truy cập

## 🤝 Đóng góp

1. Fork project
2. Tạo feature branch
3. Commit changes
4. Push và tạo Pull Request

## 📄 License

MIT License - Xem file LICENSE để biết thêm chi tiết.
