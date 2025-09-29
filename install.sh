#!/bin/bash

# Auto-installation script for Monitor System
# This script will install and configure everything automatically

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Monitor System Auto-Installer${NC}"
echo -e "${YELLOW}This script will install and configure the monitoring system${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run this script as root${NC}"
    echo -e "${YELLOW}Run as regular user, the script will ask for sudo when needed${NC}"
    exit 1
fi

# Check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}✅ Linux detected${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✅ macOS detected${NC}"
else
    echo -e "${YELLOW}⚠️  Unsupported OS: $OSTYPE${NC}"
    echo -e "${YELLOW}This script is designed for Linux and macOS${NC}"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}📦 Installing Docker...${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}Please install Docker Desktop for macOS from: https://www.docker.com/products/docker-desktop${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

# Install Docker Compose if not present
if ! docker compose version &> /dev/null; then
    echo -e "${BLUE}📦 Installing Docker Compose...${NC}"
    # Docker Compose is now included with Docker Desktop and newer Docker installations
    # For older systems, install docker-compose (legacy)
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
else
    echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi

# Create .env from template
if [ ! -f .env ]; then
    echo -e "${BLUE}📝 Creating .env file...${NC}"
    cp env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env file with your actual values${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Setup secrets
echo -e "${BLUE}🔐 Setting up secrets...${NC}"
./monitor setup

# Run security audit
echo -e "${BLUE}🔍 Running security audit...${NC}"
./monitor audit

# Start the system
echo -e "${BLUE}🚀 Starting monitoring system...${NC}"
./monitor start

echo -e "${GREEN}✅ Installation completed successfully!${NC}"
echo ""
echo -e "${BLUE}🌐 Access your services:${NC}"
echo "   - Portainer: http://localhost:9000"
echo "   - Grafana: http://localhost:3000"
echo "   - Prometheus: http://localhost:9090"
echo "   - cAdvisor: http://localhost:8080"
echo "   - Node Exporter: http://localhost:9100"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "   1. Configure Tailscale: ./monitor tailscale"
echo "   2. Setup VM2 connection: ./monitor vm2"
echo "   3. Check system status: ./monitor status"
echo "   4. Read SECURITY.md for security best practices"
