# Variables
DOCKER_USERNAME=softvence
PACKAGE_NAME=nestjs_starter
PACKAGE_VERSION=latest

# Docker image name
APP_IMAGE := $(DOCKER_USERNAME)/$(PACKAGE_NAME):$(PACKAGE_VERSION)

# Compose file
COMPOSE_FILE := compose.yaml
DEV_COMPOSE_FILE := compose.dev.yaml

# Dockerfile
DOCKERFILE := Dockerfile
DEV_DOCKERFILE := Dockerfile.dev

.PHONY: help build up upd down restart logs clean push containers volumes networks images dev-services dev-services-down dev-local dev-docker dev-docker-build dev-docker-down dev-docker-logs dev-docker-clean

help:
	@echo "Available commands:"
	@echo "  make build             Build the Docker image"
	@echo "  make up                Start containers (attached) - production"
	@echo "  make upd               Start containers (detached) - production"
	@echo "  make down              Stop containers"
	@echo "  make restart           Restart containers"
	@echo "  make logs              Show logs of all services"
	@echo "  make clean             Remove containers, networks, volumes created by compose"
	@echo "  make push              Push the Docker image to Docker Hub"
	@echo "  make containers        List containers from compose"
	@echo "  make volumes           List volumes"
	@echo "  make networks          List networks"
	@echo "  make images            List images"
	@echo ""
	@echo "Development commands:"
	@echo "  make dev-services      Start PostgreSQL and Redis for local development"
	@echo "  make dev-services-down Stop development services"
	@echo "  make dev-local         Start dev services and run pnpm dev locally"
	@echo ""
	@echo "Docker Development (Full Stack with Live Reload):"
	@echo "  make dev-docker        Start full Docker dev environment with live reload"
	@echo "  make dev-docker-build  Rebuild and start Docker dev environment"
	@echo "  make dev-docker-down   Stop Docker dev environment"
	@echo "  make dev-docker-logs   Show logs from Docker dev environment"
	@echo "  make dev-docker-clean  Clean Docker dev environment (remove volumes)"

# Build the Docker image
build:
	docker build -t $(APP_IMAGE) .

# Start containers (attached) - production
up:
	docker compose -f $(COMPOSE_FILE) --profile prod up --remove-orphans

# Start containers (detached) - production
upd:
	docker compose -f $(COMPOSE_FILE) --profile prod up -d

# Stop containers
down:
	docker compose -f $(COMPOSE_FILE) --profile prod down

# Restart containers
restart:
	docker compose -f $(COMPOSE_FILE) --profile prod restart
	docker compose -f $(COMPOSE_FILE) --profile prod up

# Logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# Cleanup
clean:
	docker compose -f $(COMPOSE_FILE) --profile prod down --volumes --remove-orphans
	docker rmi $(APP_IMAGE) || true

# List containers
containers:
	docker compose -f $(COMPOSE_FILE) ps

# List volumes
volumes:
	docker volume ls

# List networks
networks:
	docker network ls

# List images
images:
	docker images

# Push image
push:
	docker push $(APP_IMAGE)

# Development commands
# Start development services (PostgreSQL and Redis only)
dev-services:
	docker compose -f $(COMPOSE_FILE) --profile dev up -d

# Stop development services
dev-services-down:
	docker compose -f $(COMPOSE_FILE) --profile dev down

# Run local dev (without docker for api)
dev-local:
	@echo "Starting development services..."
	@$(MAKE) dev-services
	@echo "Waiting for services to be ready..."
	@sleep 3
	@echo "Starting application in development mode..."
	pnpm dev

# Docker Development (Full Stack with Live Reload)
# Start full Docker dev environment with live reload
dev-build:
	docker compose -f $(DEV_COMPOSE_FILE) build

dev-docker:
	docker compose -f $(DEV_COMPOSE_FILE) up

# Rebuild and start Docker dev environment
dev-docker-build:
	docker compose -f compose.dev.yaml up --build

# Stop Docker dev environment
dev-docker-down:
	docker compose -f compose.dev.yaml down

# Show logs from Docker dev environment
dev-docker-logs:
	docker compose -f compose.dev.yaml logs -f

# Clean Docker dev environment (remove volumes)
dev-docker-clean:
	docker compose -f compose.dev.yaml down --volumes --remove-orphans

