# Variables
DOCKER_USERNAME=softvence
PACKAGE_NAME=nestjs_starter
PACKAGE_VERSION=latest

# Docker image name
APP_IMAGE := $(DOCKER_USERNAME)/$(PACKAGE_NAME):$(PACKAGE_VERSION)

# Compose files
COMPOSE_FILE := compose.yaml
DEV_COMPOSE_FILE := compose.dev.yaml

# Docker files
DOCKERFILE := Dockerfile
DEV_DOCKERFILE := Dockerfile.dev

.PHONY: help build up start stop restart logs logs-api clean push ps dev-up dev-stop dev-logs dev-clean dev-ps local-up local-down local images volumes networks backup-list backup-manual backup-logs backup-restore

help:
	@echo "Available commands:"
	@echo ""
	@echo "Production Commands (Default):"
	@echo "  make build             Build the Docker image"
	@echo "  make up                Start containers (attached)"
	@echo "  make start             Start containers (detached)"
	@echo "  make stop              Stop containers"
	@echo "  make restart           Restart containers"
	@echo "  make logs              Show logs"
	@echo "  make logs-api          Show API logs"
	@echo "  make clean             Remove containers, networks, volumes"
	@echo "  make push              Push image to Docker Hub"
	@echo "  make ps                List production containers"
	@echo ""
	@echo "Development Commands (dev-* - Full Docker):"
	@echo "  make dev-up            Start full Docker dev environment (detached)"
	@echo "  make dev-stop          Stop Docker dev environment"
	@echo "  make dev-logs          Show logs from Docker dev environment"
	@echo "  make dev-clean         Clean Docker dev environment (remove volumes)"
	@echo "  make dev-ps            List development containers"
	@echo ""
	@echo "Local Development Commands (local-* - Hybrid):"
	@echo "  make local-up          Start dependencies (DB, Redis) only"
	@echo "  make local-down        Stop dependencies"
	@echo "  make local             Start deps and run 'pnpm dev' locally"
	@echo ""
	@echo "General / Inspection:"
	@echo "  make images            List images"
	@echo "  make volumes           List volumes"
	@echo "  make networks          List networks"
	@echo ""
	@echo "Backup Commands:"
	@echo "  make backup-list       List available backups"
	@echo "  make backup-manual     Create manual backup"
	@echo "  make backup-logs       Show backup service logs"
	@echo "  make backup-restore    Restore from backup (interactive)"
	@echo ""

# ==========================================
# Production Commands (Default)
# ==========================================

build:
	docker build -t $(APP_IMAGE) .

up:
	docker compose -f $(COMPOSE_FILE) --profile prod up --remove-orphans

start:
	docker compose -f $(COMPOSE_FILE) --profile prod up -d

stop:
	docker compose -f $(COMPOSE_FILE) --profile prod down

restart:
	docker compose -f $(COMPOSE_FILE) --profile prod restart
	docker compose -f $(COMPOSE_FILE) --profile prod up -d

logs:
	docker compose -f $(COMPOSE_FILE) --profile prod logs -f

logs-api:
	docker compose -f $(COMPOSE_FILE) --profile prod logs -f api

clean:
	docker compose -f $(COMPOSE_FILE) --profile prod down --volumes --remove-orphans
	docker rmi $(APP_IMAGE) || true

push:
	docker push $(APP_IMAGE)

ps:
	docker compose -f $(COMPOSE_FILE) --profile prod ps -a

# ==========================================
# Development Commands (Full Docker)
# ==========================================
dev-build:
	docker compose -f $(DEV_COMPOSE_FILE) build

dev-up:
	docker compose -f $(DEV_COMPOSE_FILE) up -d

dev-stop:
	docker compose -f $(DEV_COMPOSE_FILE) down

dev-logs:
	docker compose -f $(DEV_COMPOSE_FILE) logs -f

dev-clean:
	docker compose -f $(DEV_COMPOSE_FILE) down --volumes --remove-orphans

dev-ps:
	docker compose -f $(DEV_COMPOSE_FILE) ps -a

# ==========================================
# Local Development Commands (Hybrid)
# ==========================================

local-up:
	docker compose -f $(COMPOSE_FILE) --profile dev up -d

local-down:
	docker compose -f $(COMPOSE_FILE) --profile dev down

local:
	@echo "Starting development services..."
	@$(MAKE) local-up
	@echo "Waiting for services to be ready..."
	@sleep 3
	@echo "Installing dependencies..."
	pnpm install
	@echo "Database migrations..."
	npx prisma migrate deploy
	@echo "Starting application in development mode..."
	pnpm dev

# ==========================================
# General / Inspection
# ==========================================

images:
	docker images

volumes:
	docker volume ls

networks:
	docker network ls

# ==========================================
# Backup Commands
# ==========================================

backup-list:
	@echo "Available backups:"
	@if docker ps -f name=$(PACKAGE_NAME)_backup --format "{{.Names}}" | grep -q $(PACKAGE_NAME)_backup; then \
		docker exec $(PACKAGE_NAME)_backup /scripts/restore-database.sh list; \
	else \
		echo "Backup service is not running. Start it with 'make start' or 'make dev-up'"; \
	fi

backup-manual:
	@echo "Creating manual backup..."
	@if docker ps -f name=$(PACKAGE_NAME)_backup --format "{{.Names}}" | grep -q $(PACKAGE_NAME)_backup; then \
		docker exec $(PACKAGE_NAME)_backup /scripts/backup-database.sh; \
	else \
		echo "Backup service is not running. Start it with 'make start' or 'make dev-up'"; \
	fi

backup-logs:
	@echo "Backup service logs:"
	@if docker ps -f name=$(PACKAGE_NAME)_backup --format "{{.Names}}" | grep -q $(PACKAGE_NAME)_backup; then \
		docker exec $(PACKAGE_NAME)_backup tail -f /var/log/backup/cron.log; \
	else \
		echo "Backup service is not running. Start it with 'make start' or 'make dev-up'"; \
	fi

backup-restore:
	@echo "Available backups:"
	@if docker ps -f name=$(PACKAGE_NAME)_backup --format "{{.Names}}" | grep -q $(PACKAGE_NAME)_backup; then \
		docker exec $(PACKAGE_NAME)_backup /scripts/restore-database.sh list; \
		echo ""; \
		read -p "Enter backup filename to restore: " backup_file; \
		if [ -n "$$backup_file" ]; then \
			echo "WARNING: This will replace the current database. Are you sure? [y/N]"; \
			read -r confirm; \
			if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
				docker exec $(PACKAGE_NAME)_backup /bin/bash -c "FORCE_RESTORE=true /scripts/restore-database.sh restore $$backup_file"; \
			else \
				echo "Restore cancelled."; \
			fi; \
		fi; \
	else \
		echo "Backup service is not running. Start it with 'make start' or 'make dev-up'"; \
	fi
