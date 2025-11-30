# Variables
DOCKER_USERNAME=softvence
PACKAGE_NAME=nestjs_starter
PACKAGE_VERSION=latest

# Docker image name
APP_IMAGE := $(DOCKER_USERNAME)/$(PACKAGE_NAME):$(PACKAGE_VERSION)

# Compose file
COMPOSE_FILE := compose.yaml

.PHONY: help build up upd down restart logs clean push containers volumes networks images dev-services dev-services-down dev

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
	@echo "  make dev               Start dev services and run pnpm dev"

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

# Start dev services and run pnpm dev
dev:
	@echo "Starting development environment..."
	docker compose -f $(COMPOSE_FILE) --profile dev up --build

# Build dev image explicitly
dev-build:
	docker compose -f $(COMPOSE_FILE) --profile dev build

# Run local dev (without docker for api)
dev-local:
	@echo "Starting development services..."
	@$(MAKE) dev-services
	@echo "Waiting for services to be ready..."
	@sleep 3
	@echo "Starting application in development mode..."
	pnpm dev
