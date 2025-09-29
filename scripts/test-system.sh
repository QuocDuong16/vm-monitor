#!/bin/bash

# System test script - comprehensive testing of monitoring system
# Usage: ./scripts/test-system.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Running comprehensive system tests...${NC}"

# Test 1: Docker and Docker Compose
echo -e "\n${YELLOW}1. Testing Docker and Docker Compose...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is available${NC}"
    docker --version
else
    echo -e "${RED}❌ Docker not found${NC}"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose is available${NC}"
    docker-compose --version
else
    echo -e "${RED}❌ Docker Compose not found${NC}"
    exit 1
fi

# Test 2: Configuration files
echo -e "\n${YELLOW}2. Testing configuration files...${NC}"
required_files=(
    "docker-compose.yml"
    "config/prometheus.yml"
    "config/prometheus/alerts.yml"
    "config/grafana/provisioning/datasources/prometheus.yml"
    "config/grafana/provisioning/dashboards/dashboard.yml"
    "config/syslog/syslog-ng.conf"
    "env.example"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
        exit 1
    fi
done

# Test 3: Docker Compose syntax
echo -e "\n${YELLOW}3. Testing Docker Compose syntax...${NC}"
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose syntax is valid${NC}"
else
    echo -e "${RED}❌ Docker Compose syntax error${NC}"
    docker-compose config
    exit 1
fi

# Test 4: Environment setup
echo -e "\n${YELLOW}4. Testing environment setup...${NC}"
if [ -f .env ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    source .env
    
    # Check required variables
    required_vars=("GRAFANA_PASSWORD")
    for var in "${required_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            echo -e "${GREEN}✅ $var is set${NC}"
        else
            echo -e "${YELLOW}⚠️  $var is not set${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  .env file not found, using env.example${NC}"
    if [ -f env.example ]; then
        echo -e "${GREEN}✅ env.example exists${NC}"
    else
        echo -e "${RED}❌ env.example missing${NC}"
        exit 1
    fi
fi

# Test 5: Secrets directory
echo -e "\n${YELLOW}5. Testing secrets setup...${NC}"
if [ -d "secrets" ]; then
    echo -e "${GREEN}✅ Secrets directory exists${NC}"
    if [ -f "secrets/grafana_password.txt" ]; then
        echo -e "${GREEN}✅ Grafana password file exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Grafana password file missing${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Secrets directory not found${NC}"
fi

# Test 6: Scripts permissions
echo -e "\n${YELLOW}6. Testing scripts permissions...${NC}"
scripts=(
    "monitor"
    "scripts/monitor.sh"
    "scripts/health-check.sh"
    "install.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✅ $script is executable${NC}"
        else
            echo -e "${YELLOW}⚠️  $script is not executable, fixing...${NC}"
            chmod +x "$script"
        fi
    else
        echo -e "${RED}❌ $script missing${NC}"
    fi
done

# Test 7: Network connectivity (if system is running)
echo -e "\n${YELLOW}7. Testing network connectivity...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ System is running, testing connectivity...${NC}"
    
    # Test Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        echo -e "${GREEN}✅ Prometheus is responding${NC}"
    else
        echo -e "${RED}❌ Prometheus is not responding${NC}"
    fi
    
    # Test Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo -e "${GREEN}✅ Grafana is responding${NC}"
    else
        echo -e "${RED}❌ Grafana is not responding${NC}"
    fi
    
    # Test Node Exporter
    if curl -s http://localhost:9100/metrics > /dev/null; then
        echo -e "${GREEN}✅ Node Exporter is responding${NC}"
    else
        echo -e "${RED}❌ Node Exporter is not responding${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  System is not running, skipping connectivity tests${NC}"
fi

# Test 8: Security audit
echo -e "\n${YELLOW}8. Running security audit...${NC}"
if [ -f "scripts/monitor.sh" ]; then
    ./monitor audit
else
    echo -e "${YELLOW}⚠️  Security audit script not found${NC}"
fi

echo -e "\n${GREEN}✅ System tests completed!${NC}"
echo -e "${BLUE}💡 If all tests passed, your monitoring system is ready to use!${NC}"
