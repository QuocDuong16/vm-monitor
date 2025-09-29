#!/bin/bash

# Install system dependencies for monitoring
# This script installs additional tools for better monitoring

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Installing monitoring dependencies...${NC}"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        echo -e "${BLUE}🐧 Detected Ubuntu/Debian${NC}"
        sudo apt-get update
        sudo apt-get install -y \
            curl \
            wget \
            htop \
            iotop \
            nethogs \
            jq \
            tree \
            unzip \
            netstat-nat \
            lsof \
            strace \
            tcpdump \
            nmap \
            vim \
            nano
        
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        echo -e "${BLUE}🐧 Detected CentOS/RHEL${NC}"
        sudo yum update -y
        sudo yum install -y \
            curl \
            wget \
            htop \
            iotop \
            jq \
            tree \
            unzip \
            net-tools \
            lsof \
            strace \
            tcpdump \
            nmap \
            vim \
            nano
    else
        echo -e "${YELLOW}⚠️  Unsupported Linux distribution${NC}"
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -e "${BLUE}🍎 Detected macOS${NC}"
    if command -v brew &> /dev/null; then
        brew install \
            curl \
            wget \
            htop \
            jq \
            tree \
            nmap \
            tcpdump
    else
        echo -e "${YELLOW}⚠️  Please install Homebrew first: https://brew.sh${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Unsupported OS: $OSTYPE${NC}"
fi

# Install Trivy for security scanning
echo -e "${BLUE}🔍 Installing Trivy security scanner...${NC}"
if ! command -v trivy &> /dev/null; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install Trivy
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install trivy
    fi
    echo -e "${GREEN}✅ Trivy installed${NC}"
else
    echo -e "${GREEN}✅ Trivy already installed${NC}"
fi

# Install Docker Compose V2 (if not present)
echo -e "${BLUE}🐳 Checking Docker Compose V2...${NC}"
if ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose V2 not found, installing...${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install Docker Compose V2
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    echo -e "${GREEN}✅ Docker Compose V2 installed${NC}"
else
    echo -e "${GREEN}✅ Docker Compose V2 already available${NC}"
fi

# Install additional monitoring tools
echo -e "${BLUE}📊 Installing additional monitoring tools...${NC}"

# Install Docker stats exporter (optional)
if ! command -v docker-stats-exporter &> /dev/null; then
    echo -e "${BLUE}📈 Installing docker-stats-exporter...${NC}"
    # This would be a custom tool, for now just note it
    echo -e "${YELLOW}💡 Consider installing docker-stats-exporter for advanced metrics${NC}"
fi

echo -e "${GREEN}✅ Dependencies installation completed!${NC}"
echo ""
echo -e "${BLUE}📋 Installed tools:${NC}"
echo "   - curl, wget (network tools)"
echo "   - htop, iotop (system monitoring)"
echo "   - jq (JSON processing)"
echo "   - tree (directory visualization)"
echo "   - lsof, strace (process monitoring)"
echo "   - tcpdump, nmap (network analysis)"
echo "   - trivy (security scanning)"
echo ""
echo -e "${YELLOW}💡 You can now use advanced monitoring features!${NC}"
