#!/bin/bash

# Script quản lý hệ thống Monitor VM1 - All-in-One
# Tác giả: Monitor System
# Mô tả: Quản lý toàn bộ hệ thống monitor và bảo mật

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
show_help() {
    echo -e "${BLUE}🔧 Monitor System Management${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       - Khởi động hệ thống monitor"
    echo "  stop        - Dừng hệ thống monitor"
    echo "  restart     - Restart hệ thống monitor"
    echo "  status      - Kiểm tra trạng thái hệ thống"
    echo "  setup       - Thiết lập bảo mật và secrets"
    echo "  audit       - Kiểm tra bảo mật"
    echo "  demo        - Demo các vấn đề bảo mật"
    echo "  build       - Build Docker images an toàn"
    echo "  cleanup     - Xóa hoàn toàn hệ thống"
    echo "  vm2         - Thiết lập kết nối VM2"
    echo "  tailscale   - Cài đặt Tailscale"
    echo "  backup      - Backup dữ liệu hệ thống"
    echo "  restore     - Restore dữ liệu hệ thống"
    echo "  update      - Cập nhật Docker images"
    echo "  logs        - Xem logs của services"
    echo "  help        - Hiển thị trợ giúp này"
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker chưa được cài đặt!${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose chưa được cài đặt!${NC}"
        exit 1
    fi
}

setup_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  File .env không tồn tại. Tạo từ env.example...${NC}"
        cp env.example .env
        echo -e "${YELLOW}📝 Vui lòng chỉnh sửa file .env với thông tin thực tế!${NC}"
        echo "   - CLOUDFLARE_TUNNEL_TOKEN: Token từ Cloudflare (tùy chọn)"
        echo "   - GRAFANA_PASSWORD: Mật khẩu Grafana"
        echo "   - VM2_TAILSCALE_HOST: Tailscale hostname của VM2"
        read -p "Nhấn Enter sau khi đã cấu hình .env..."
    fi
}

create_directories() {
    echo -e "${BLUE}📁 Tạo thư mục cần thiết...${NC}"
    mkdir -p config/grafana/provisioning/datasources
    mkdir -p config/grafana/provisioning/dashboards
    mkdir -p config/syslog
    mkdir -p logs
}

start_system() {
    echo -e "${GREEN}🚀 Đang khởi động hệ thống Monitor VM1...${NC}"
    
    check_docker
    setup_env
    create_directories
    
    # Khởi động stack
    echo -e "${BLUE}🐳 Khởi động Docker containers...${NC}"
    docker-compose up -d
    
    # Kiểm tra trạng thái
    echo -e "${BLUE}⏳ Đang kiểm tra trạng thái services...${NC}"
    sleep 10
    
    # Hiển thị trạng thái
    echo -e "${GREEN}📊 Trạng thái các services:${NC}"
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}✅ Hệ thống Monitor VM1 đã khởi động thành công!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Truy cập các services:${NC}"
    echo "   - Portainer: http://localhost:9000"
    echo "   - Grafana: http://localhost:3000 (admin/admin123)"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - cAdvisor: http://localhost:8080"
    echo "   - Node Exporter: http://localhost:9100"
}

stop_system() {
    echo -e "${YELLOW}🛑 Đang dừng hệ thống Monitor VM1...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ Hệ thống Monitor VM1 đã dừng thành công!${NC}"
}

restart_system() {
    echo -e "${YELLOW}🔄 Đang restart hệ thống Monitor VM1...${NC}"
    docker-compose restart
    echo -e "${BLUE}⏳ Đang kiểm tra trạng thái services...${NC}"
    sleep 5
    echo -e "${GREEN}📊 Trạng thái các services:${NC}"
    docker-compose ps
    echo -e "${GREEN}✅ Hệ thống Monitor VM1 đã restart thành công!${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Trạng thái hệ thống Monitor VM1${NC}"
    echo "=================================="
    
    check_docker
    
    # Trạng thái containers
    echo ""
    echo -e "${BLUE}🐳 Trạng thái Containers:${NC}"
    docker-compose ps
    
    # Sử dụng tài nguyên
    echo ""
    echo -e "${BLUE}💾 Sử dụng tài nguyên:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Kiểm tra ports
    echo ""
    echo -e "${BLUE}🌐 Ports đang lắng nghe:${NC}"
    netstat -tulpn | grep -E ":(3000|8080|9000|9090|9100|9443)" || echo "Không có ports nào đang lắng nghe"
    
    # Kiểm tra logs gần đây
    echo ""
    echo -e "${BLUE}📝 Logs gần đây (5 dòng cuối):${NC}"
    docker-compose logs --tail=5
    
    # Kiểm tra kết nối VM2 qua Tailscale (nếu có)
    if [ -f .env ]; then
        source .env
        if [ ! -z "$VM2_TAILSCALE_HOST" ] && [ "$VM2_TAILSCALE_HOST" != "vm2-hostname" ]; then
            echo ""
            echo -e "${BLUE}🔗 Kiểm tra kết nối VM2 qua Tailscale ($VM2_TAILSCALE_HOST):${NC}"
            if ping -c 1 -W 3 "$VM2_TAILSCALE_HOST" &> /dev/null; then
                echo -e "${GREEN}✅ VM2 có thể kết nối qua Tailscale${NC}"
            else
                echo -e "${RED}❌ Không thể kết nối VM2 qua Tailscale${NC}"
            fi
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✅ Kiểm tra hoàn tất!${NC}"
}

setup_security() {
    echo -e "${GREEN}🔐 Setting up Docker secrets...${NC}"
    
    SECRETS_DIR="./secrets"
    
    # Create secrets directory
    mkdir -p "${SECRETS_DIR}"
    chmod 700 "${SECRETS_DIR}"
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  .env file not found. Please create it from .env.example${NC}"
        exit 1
    fi
    
    # Load environment variables
    source .env
    
    # Create Grafana password file
    if [ -n "${GRAFANA_PASSWORD:-}" ]; then
        echo "${GRAFANA_PASSWORD}" > "${SECRETS_DIR}/grafana_password.txt"
        chmod 600 "${SECRETS_DIR}/grafana_password.txt"
        echo -e "${GREEN}✅ Created grafana_password.txt${NC}"
    else
        echo -e "${RED}❌ GRAFANA_PASSWORD not found in .env${NC}"
        exit 1
    fi
    
    # Create Cloudflare token file (if exists)
    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        echo "${CLOUDFLARE_TUNNEL_TOKEN}" > "${SECRETS_DIR}/cloudflare_token.txt"
        chmod 600 "${SECRETS_DIR}/cloudflare_token.txt"
        echo -e "${GREEN}✅ Created cloudflare_token.txt${NC}"
    else
        echo -e "${YELLOW}⚠️  CLOUDFLARE_TUNNEL_TOKEN not found in .env (optional)${NC}"
    fi
    
    # Set proper permissions
    chown -R $(id -u):$(id -g) "${SECRETS_DIR}"
    
    echo -e "${GREEN}🔒 Secrets setup completed!${NC}"
    echo -e "${YELLOW}💡 Security tips:${NC}"
    echo "   - Never commit the secrets/ directory to git"
    echo "   - Use strong, unique passwords"
    echo "   - Rotate secrets regularly"
}

security_audit() {
    echo -e "${BLUE}🔍 Running Docker security audit...${NC}"
    
    # Check .dockerignore
    echo -e "\n${YELLOW}1. Checking .dockerignore...${NC}"
    if [ -f .dockerignore ]; then
        echo -e "${GREEN}✅ .dockerignore exists${NC}"
        if grep -q "\.env" .dockerignore && grep -q "\.git" .dockerignore && grep -q "id_rsa" .dockerignore; then
            echo -e "${GREEN}✅ .dockerignore covers sensitive files${NC}"
        else
            echo -e "${RED}❌ .dockerignore missing some sensitive file patterns${NC}"
        fi
    else
        echo -e "${RED}❌ .dockerignore not found${NC}"
    fi
    
    # Check Docker Compose secrets
    echo -e "\n${YELLOW}2. Checking Docker Compose secrets usage...${NC}"
    if grep -q "secrets:" docker-compose.yml; then
        echo -e "${GREEN}✅ Docker Compose uses secrets${NC}"
    else
        echo -e "${RED}❌ Docker Compose not using secrets${NC}"
    fi
    
    # Check non-root users
    echo -e "\n${YELLOW}3. Checking for non-root users...${NC}"
    if grep -q "user:" docker-compose.yml; then
        echo -e "${GREEN}✅ Non-root users specified${NC}"
    else
        echo -e "${YELLOW}⚠️  Consider specifying non-root users for better security${NC}"
    fi
    
    # Check privileged containers
    echo -e "\n${YELLOW}4. Checking for privileged containers...${NC}"
    if grep -q "privileged: true" docker-compose.yml; then
        echo -e "${YELLOW}⚠️  Found privileged containers - review if necessary${NC}"
    else
        echo -e "${GREEN}✅ No privileged containers found${NC}"
    fi
    
    # Check secrets directory
    echo -e "\n${YELLOW}5. Checking secrets directory...${NC}"
    if [ -d "secrets" ]; then
        echo -e "${GREEN}✅ Secrets directory exists${NC}"
        if [ "$(stat -c %a secrets 2>/dev/null)" = "700" ]; then
            echo -e "${GREEN}✅ Secrets directory has correct permissions (700)${NC}"
        else
            echo -e "${RED}❌ Secrets directory permissions too open: $(stat -c %a secrets 2>/dev/null)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Secrets directory not found - run setup command${NC}"
    fi
    
    echo -e "\n${BLUE}🔍 Security audit completed!${NC}"
}

demo_security() {
    echo -e "${BLUE}🔒 Docker Security Demo${NC}"
    echo -e "${YELLOW}Script này sẽ demo các vấn đề bảo mật phổ biến và cách fix${NC}\n"
    
    # Run security audit with more details
    security_audit
    
    echo -e "\n${YELLOW}💡 Các bước tiếp theo:${NC}"
    echo "   1. Fix các vấn đề được đánh dấu ❌"
    echo "   2. Review các cảnh báo ⚠️"
    echo "   3. Chạy setup: $0 setup"
    echo "   4. Đọc SECURITY.md để biết thêm chi tiết"
}

build_secure() {
    echo -e "${GREEN}🔒 Building secure Docker image...${NC}"
    
    # Default values
    IMAGE_NAME=${1:-"monitoring-app"}
    TAG=${2:-"latest"}
    FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  Warning: .env file not found. Using .env.example${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
        else
            echo -e "${RED}❌ Error: No .env or .env.example file found${NC}"
            exit 1
        fi
    fi
    
    # Load environment variables
    source .env
    
    # Enable BuildKit
    export DOCKER_BUILDKIT=1
    
    # Build with secrets (if NPM_TOKEN exists)
    if [ -n "${NPM_TOKEN:-}" ]; then
        echo -e "${GREEN}🔑 Using BuildKit secrets for NPM_TOKEN${NC}"
        docker build \
            --secret id=NPM_TOKEN,env=NPM_TOKEN \
            --no-cache \
            --progress=plain \
            -t "${FULL_IMAGE_NAME}" \
            -f Dockerfile.template \
            .
    else
        echo -e "${YELLOW}⚠️  No NPM_TOKEN found, building without secrets${NC}"
        docker build \
            --no-cache \
            --progress=plain \
            -t "${FULL_IMAGE_NAME}" \
            -f Dockerfile.template \
            .
    fi
    
    # Security scan with Trivy (if available)
    if command -v trivy &> /dev/null; then
        echo -e "${GREEN}🔍 Running security scan with Trivy...${NC}"
        trivy image --severity HIGH,CRITICAL "${FULL_IMAGE_NAME}"
    else
        echo -e "${YELLOW}⚠️  Trivy not found. Install it for security scanning:${NC}"
        echo "   https://aquasecurity.github.io/trivy/"
    fi
    
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
}

cleanup_system() {
    echo -e "${RED}⚠️  CẢNH BÁO: Script này sẽ xóa hoàn toàn hệ thống monitor!${NC}"
    echo "   - Tất cả containers sẽ bị xóa"
    echo "   - Tất cả volumes sẽ bị xóa"
    echo "   - Dữ liệu Grafana, Prometheus sẽ mất"
    echo ""
    
    read -p "Bạn có chắc chắn muốn tiếp tục? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}❌ Hủy bỏ thao tác cleanup.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}🗑️  Đang dừng và xóa containers...${NC}"
    docker-compose down -v
    
    echo -e "${YELLOW}🗑️  Đang xóa images...${NC}"
    docker-compose down --rmi all
    
    echo -e "${YELLOW}🗑️  Đang xóa volumes...${NC}"
    docker volume prune -f
    
    echo -e "${YELLOW}🗑️  Đang xóa networks...${NC}"
    docker network prune -f
    
    echo -e "${GREEN}✅ Cleanup hoàn tất!${NC}"
    echo -e "${BLUE}💡 Để cài đặt lại: $0 start${NC}"
}

setup_vm2() {
    echo -e "${BLUE}🔗 Thiết lập kết nối với VM2...${NC}"
    
    # Kiểm tra file .env
    if [ ! -f .env ]; then
        echo -e "${RED}❌ File .env không tồn tại. Chạy $0 start trước!${NC}"
        exit 1
    fi
    
    source .env
    
    # Nhập thông tin VM2
    echo -e "${BLUE}📝 Nhập thông tin VM2:${NC}"
    read -p "Tailscale hostname của VM2: " vm2_hostname
    read -p "SSH Port (mặc định 22): " vm2_ssh_port
    vm2_ssh_port=${vm2_ssh_port:-22}
    
    # Cập nhật .env
    sed -i "s/VM2_TAILSCALE_HOST=.*/VM2_TAILSCALE_HOST=$vm2_hostname/" .env
    sed -i "s/VM2_SSH_PORT=.*/VM2_SSH_PORT=$vm2_ssh_port/" .env
    
    echo -e "${GREEN}✅ Đã cập nhật thông tin VM2${NC}"
    
    # Kiểm tra kết nối Tailscale
    echo -e "${BLUE}🔍 Kiểm tra kết nối Tailscale với VM2...${NC}"
    if ping -c 1 -W 3 "$vm2_hostname" &> /dev/null; then
        echo -e "${GREEN}✅ VM2 có thể kết nối qua Tailscale${NC}"
    else
        echo -e "${RED}❌ Không thể kết nối VM2 qua Tailscale. Kiểm tra:${NC}"
        echo "   - VM2 đã join Tailscale chưa?"
        echo "   - Hostname có đúng không?"
        echo "   - Tailscale đang chạy trên cả 2 VM?"
        exit 1
    fi
    
    echo -e "${GREEN}✅ VM2 setup completed!${NC}"
}

install_tailscale() {
    echo -e "${BLUE}🔗 Cài đặt Tailscale trên VM1...${NC}"
    
    # Kiểm tra Tailscale đã cài đặt chưa
    if command -v tailscale &> /dev/null; then
        echo -e "${GREEN}✅ Tailscale đã được cài đặt${NC}"
        tailscale status
        exit 0
    fi
    
    # Cài đặt Tailscale
    echo -e "${BLUE}📦 Đang cài đặt Tailscale...${NC}"
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo usermod -aG tailscale $USER
    
    echo -e "${GREEN}✅ Tailscale đã được cài đặt thành công!${NC}"
    echo ""
    echo -e "${BLUE}📋 Bước tiếp theo:${NC}"
    echo "1. Đăng xuất và đăng nhập lại để áp dụng group permissions"
    echo "2. Chạy: sudo tailscale up"
    echo "3. Lấy hostname của VM1: tailscale status"
    echo "4. Cập nhật VM2_TAILSCALE_HOST trong file .env"
}

backup_system() {
    echo -e "${GREEN}💾 Creating system backup...${NC}"
    
    BACKUP_DIR="./backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="monitor_backup_${TIMESTAMP}.tar.gz"
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Stop system for consistent backup
    echo -e "${YELLOW}🛑 Stopping system for backup...${NC}"
    docker-compose down
    
    # Create backup
    echo -e "${BLUE}📦 Creating backup archive...${NC}"
    tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
        --exclude='backups' \
        --exclude='logs' \
        --exclude='secrets' \
        --exclude='.git' \
        --exclude='node_modules' \
        .
    
    # Restart system
    echo -e "${GREEN}🚀 Restarting system...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}✅ Backup completed: ${BACKUP_DIR}/${BACKUP_FILE}${NC}"
    echo -e "${BLUE}💡 To restore: $0 restore ${BACKUP_FILE}${NC}"
}

restore_system() {
    local backup_file=${1:-}
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}❌ Please specify backup file${NC}"
        echo -e "${BLUE}Usage: $0 restore <backup_file>${NC}"
        echo -e "${BLUE}Available backups:${NC}"
        ls -la backups/ 2>/dev/null || echo "No backups found"
        exit 1
    fi
    
    if [ ! -f "backups/${backup_file}" ]; then
        echo -e "${RED}❌ Backup file not found: backups/${backup_file}${NC}"
        exit 1
    fi
    
    echo -e "${RED}⚠️  CẢNH BÁO: Restore sẽ ghi đè dữ liệu hiện tại!${NC}"
    read -p "Bạn có chắc chắn muốn restore? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}❌ Hủy bỏ thao tác restore.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}🛑 Stopping system...${NC}"
    docker-compose down
    
    echo -e "${BLUE}📦 Extracting backup...${NC}"
    tar -xzf "backups/${backup_file}"
    
    echo -e "${GREEN}🚀 Starting system...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}✅ Restore completed!${NC}"
}

update_system() {
    echo -e "${GREEN}🔄 Updating Docker images...${NC}"
    
    # Pull latest images
    echo -e "${BLUE}📦 Pulling latest images...${NC}"
    docker-compose pull
    
    # Restart with new images
    echo -e "${BLUE}🚀 Restarting with updated images...${NC}"
    docker-compose up -d
    
    # Clean up old images
    echo -e "${BLUE}🧹 Cleaning up old images...${NC}"
    docker image prune -f
    
    echo -e "${GREEN}✅ Update completed!${NC}"
    echo -e "${BLUE}📊 Current status:${NC}"
    docker-compose ps
}

show_logs() {
    local service=${1:-}
    
    if [ -z "$service" ]; then
        echo -e "${BLUE}📝 Showing logs for all services...${NC}"
        docker-compose logs -f
    else
        echo -e "${BLUE}📝 Showing logs for $service...${NC}"
        docker-compose logs -f "$service"
    fi
}

# Main script logic
case "${1:-help}" in
    start)
        start_system
        ;;
    stop)
        stop_system
        ;;
    restart)
        restart_system
        ;;
    status)
        show_status
        ;;
    setup)
        setup_security
        ;;
    audit)
        security_audit
        ;;
    demo)
        demo_security
        ;;
    build)
        build_secure "${2:-}" "${3:-}"
        ;;
    cleanup)
        cleanup_system
        ;;
    vm2)
        setup_vm2
        ;;
    tailscale)
        install_tailscale
        ;;
    backup)
        backup_system
        ;;
    restore)
        restore_system "${2:-}"
        ;;
    update)
        update_system
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
