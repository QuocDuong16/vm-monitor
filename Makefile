# Monitor System Makefile
# Usage: make <target>

.PHONY: help install start stop restart status setup audit demo build cleanup backup restore vm2 tailscale health

# Default target
help: ## Show this help message
	@echo "Monitor System - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

install: ## Auto-install the monitoring system
	@chmod +x install.sh
	@./install.sh

start: ## Start the monitoring system
	@./monitor start

stop: ## Stop the monitoring system
	@./monitor stop

restart: ## Restart the monitoring system
	@./monitor restart

status: ## Check system status
	@./monitor status

setup: ## Setup security and secrets
	@./monitor setup

audit: ## Run security audit
	@./monitor audit

demo: ## Demo security issues
	@./monitor demo

build: ## Build secure Docker images
	@./monitor build

cleanup: ## Clean up the entire system
	@./monitor cleanup

backup: ## Backup system data
	@./monitor backup

restore: ## Restore from backup (usage: make restore BACKUP=filename)
	@./monitor restore $(BACKUP)

vm2: ## Setup VM2 connection
	@./monitor vm2

tailscale: ## Install Tailscale
	@./monitor tailscale

health: ## Run health checks
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh

logs: ## Show logs for all services
	@docker-compose logs -f

logs-prometheus: ## Show Prometheus logs
	@docker-compose logs -f prometheus

logs-grafana: ## Show Grafana logs
	@docker-compose logs -f grafana

logs-portainer: ## Show Portainer logs
	@docker-compose logs -f portainer

update: ## Update all Docker images
	@docker-compose pull
	@docker-compose up -d

dev: ## Start in development mode
	@docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

prod: ## Start in production mode
	@docker-compose -f docker-compose.yml up -d

# Quick setup for new users
quick-start: install start status ## Quick start for new users
	@echo "✅ System is ready! Access your services:"
	@echo "   - Portainer: http://localhost:9000"
	@echo "   - Grafana: http://localhost:3000"
	@echo "   - Prometheus: http://localhost:9090"
