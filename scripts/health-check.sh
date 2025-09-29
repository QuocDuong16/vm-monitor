#!/bin/bash

# Health check script for monitoring system
# This script can be used as a health check for containers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if services are responding
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ $service_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is unhealthy${NC}"
        return 1
    fi
}

# Check all services
echo -e "${BLUE}🔍 Running health checks...${NC}"

# Check Prometheus
check_service "Prometheus" "http://localhost:9090/-/healthy" || exit 1

# Check Grafana
check_service "Grafana" "http://localhost:3000/api/health" || exit 1

# Check Node Exporter
check_service "Node Exporter" "http://localhost:9100/metrics" || exit 1

# Check cAdvisor
check_service "cAdvisor" "http://localhost:8080/healthz" || exit 1

# Check Portainer
check_service "Portainer" "http://localhost:9000/api/status" || exit 1

echo -e "${GREEN}✅ All services are healthy!${NC}"
