#!/bin/bash

# Monitor daemon script - runs in background to monitor system health
# Usage: ./scripts/monitor-daemon.sh [start|stop|status]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PID_FILE="./monitor-daemon.pid"
LOG_FILE="./logs/monitor-daemon.log"

# Create logs directory
mkdir -p logs

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Monitor daemon is already running${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🚀 Starting monitor daemon...${NC}"
    nohup "$0" daemon > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo -e "${GREEN}✅ Monitor daemon started (PID: $(cat "$PID_FILE"))${NC}"
    echo -e "${BLUE}📝 Logs: $LOG_FILE${NC}"
}

stop_daemon() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}⚠️  Monitor daemon is not running${NC}"
        exit 1
    fi
    
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${YELLOW}🛑 Stopping monitor daemon...${NC}"
        kill "$pid"
        rm -f "$PID_FILE"
        echo -e "${GREEN}✅ Monitor daemon stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  Monitor daemon is not running${NC}"
        rm -f "$PID_FILE"
    fi
}

status_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${GREEN}✅ Monitor daemon is running (PID: $(cat "$PID_FILE"))${NC}"
        echo -e "${BLUE}📝 Logs: $LOG_FILE${NC}"
    else
        echo -e "${RED}❌ Monitor daemon is not running${NC}"
    fi
}

# Daemon main loop
daemon_loop() {
    echo -e "${BLUE}🔍 Monitor daemon started at $(date)${NC}"
    
    while true; do
        # Check if main system is running
        if ! docker-compose ps | grep -q "Up"; then
            echo -e "${RED}❌ System down detected at $(date)${NC}"
            # Could add auto-restart logic here
        fi
        
        # Check disk space
        local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt 90 ]; then
            echo -e "${RED}⚠️  High disk usage: ${disk_usage}% at $(date)${NC}"
        fi
        
        # Check memory usage
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [ "$mem_usage" -gt 90 ]; then
            echo -e "${RED}⚠️  High memory usage: ${mem_usage}% at $(date)${NC}"
        fi
        
        # Sleep for 5 minutes
        sleep 300
    done
}

case "${1:-help}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    daemon)
        daemon_loop
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "  start  - Start the monitor daemon"
        echo "  stop   - Stop the monitor daemon"
        echo "  status - Check daemon status"
        exit 1
        ;;
esac
