# Setup & Installation

## Prerequisites

- Node.js 24+
- pnpm 10+
- Docker & Docker Compose
- PostgreSQL 17
- Redis

## Environment Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Configure the essential variables:

```bash
# App
NODE_ENV=production
PORT=3000

# Docker
DOCKER_USERNAME=softvence
PACKAGE_NAME=nestjs_starter

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/nestjs_starter_db

# AWS (For File Uploads/Backup)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET_NAME=your-bucket

# Database Backup
BACKUP_SCHEDULE=0 2 * * *
```

## Running Locally (Hybrid)

This method runs dependencies (DB, Redis) in Docker, but the application runs natively on your machine for fast feedback.

```bash
# Start dependencies
make local-up

# Run app in dev mode
pnpm dev
```

Or using the convenience command:
```bash
make local
```

## Running in Docker (Development)

This runs the entire stack (App, DB, Redis) inside Docker containers with hot reload enabled.

```bash
make dev-up
make dev-logs
```

## Running in Production

```bash
make build
make start
```
