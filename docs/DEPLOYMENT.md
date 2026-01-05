# Deployment & CI/CD

## Docker Architecture

### Production (`compose.yaml`)

- **api**: NestJS API (multi-stage build, optimized image)
- **db**: PostgreSQL 17
- **redis-master**: Redis primary node
- **redis-replica**: Redis replica for high availability
- **caddy**: Reverse proxy with auto-HTTPS handling
- **coturn**: TURN server for WebRTC
- **backup**: Automated database backup service

### Development (`compose.dev.yaml`)

- **app**: NestJS with hot reload
- **db**: PostgreSQL
- **redis-master**: Redis

## CI/CD Pipeline

The project uses GitHub Actions configured in `.github/workflows/ci-cd.yml`.

### Workflow Steps

1.  **CI Check** (Trigger: PR/Push to main)
    *   Lint check
    *   Format check
    *   Build validation

2.  **Build & Push** (Trigger: Merge to main)
    *   Builds Docker image
    *   Pushes to Docker Hub
    *   Tags: `latest`, `<version>`, `<commit-sha>`

3.  **Release** (Trigger: Automated)
    *   Uses **Semantic Release**
    *   Analyzes commits
    *   Bumps `package.json` version
    *   Generates `CHANGELOG.md`
    *   Publishes GitHub Release

### Deployment Strategy

To deploy to a VPS:

1.  **Prepare Server**: Install Docker & Docker Compose.
2.  **Environment**: Copy `.env` to the server.
3.  **Deploy**:
    ```bash
    make start
    ```
    This pulls the latest images (defined in `Makefile` and `compose.yaml`) and starts the stack.

### HTTPS with Caddy

The project includes Caddy as a reverse proxy. It automatically handles:
- SSL/TLS termination
- Certificate renewal (Let's Encrypt)
- Proxying requests to the API and other services

Ensure port `80` and `443` are open on your server.
