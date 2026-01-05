# NestJS + Prisma + AWS Starter

A production-ready, feature-rich starter template for building scalable backend applications with NestJS, Prisma ORM, and AWS integration. Includes authentication, real-time chat, file uploads, job queues, and complete Docker deployment setup.

## 🚀 Features

### Core Stack

- **NestJS** - Progressive Node.js framework
- **Prisma ORM** - Type-safe database access with split schema architecture
- **PostgreSQL** - Primary database
- **Redis** - Caching and queue management
- **TypeScript** - Full type safety
- **Docker** - Production and development containers

### Authentication & Security

- JWT-based authentication with refresh tokens
- Email verification via OTP
- Password reset flow
- Role-based access control (SUPER_ADMIN, ADMIN, USER)
- Bcrypt password hashing
- Passport.js integration

### Real-time Features

- WebSocket Gateway with Socket.IO
- Private messaging system
- Conversation management (archive, block, delete)
- WebRTC support with TURN server (coturn)
- Live reload in development

### File Management

- File upload with Multer
- AWS S3 integration
- AWS Media Convert integration
- Configurable upload limits (up to 500MB via Caddy)

### Background Jobs

- BullMQ job queues
- Event-driven architecture with EventEmitter
- Scheduled tasks with @nestjs/schedule

### Developer Experience

- **Husky** - Git hooks made easy
- **Commitizen** - Interactive commit generator
- **Commitlint** - Lint commit messages
- **Semantic Release** - Automated versioning and changelogs
- **Lint Staged** - Run linters on staged files
- **ESLint + Prettier** - Automated linting and formatting
- **CI/CD** - GitHub Actions workflow
- **Swagger** - API documentation
- **Split Prisma Schema** - Organized database models

## 📁 Project Structure

```text
├── .github/workflows/     # CI/CD configuration
├── .husky/               # Git hooks
├── prisma/
│   ├── schema/          # Split Prisma schema files
│   ├── migrations/      # Database migrations
│   └── generated/       # Generated Prisma Client
├── scripts/             # Utility scripts (ci-hooks.js)
├── src/
│   ├── main.ts         # Application entry point
│   ├── app.module.ts   # Root module
│   ├── core/           # Infrastructure & global configs
│   │   ├── filter/     # Exception filters
│   │   ├── jwt/        # JWT strategy & guards
│   │   ├── middleware/ # Logger middleware
│   │   ├── pipe/       # Validation pipes
│   │   └── socket/     # WebSocket base gateway
│   ├── common/         # Shared utilities
│   │   ├── dto/        # Data Transfer Objects
│   │   ├── enum/       # Shared enums
│   │   └── utils/      # Helper functions
│   ├── lib/            # Feature modules (reusable)
│   │   ├── chat/       # Real-time chat
│   │   ├── file/       # File uploads
│   │   ├── mail/       # Email service
│   │   ├── prisma/     # Prisma service
│   │   ├── queue/      # Job queues
│   │   ├── seed/       # Database seeding
│   │   └── utils/      # Feature utilities
│   └── main/           # Application modules
│       ├── auth/       # Authentication
│       └── upload/     # Upload endpoints
├── Dockerfile          # Production Docker image
├── Dockerfile.dev      # Development Docker image
├── compose.yaml        # Production Docker Compose
├── compose.dev.yaml    # Development Docker Compose
├── Caddyfile          # Reverse proxy configuration
└── Makefile           # Command shortcuts

```

## 🛠️ Setup & Installation

### Prerequisites

- Node.js 24+
- pnpm 10+
- Docker & Docker Compose
- PostgreSQL 17
- Redis

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# App
NODE_ENV= production
BASE_URL= http://localhost:3000
PORT= 3000

# Docker
DOCKER_USERNAME=softvence
PACKAGE_NAME=nestjs_starter
PACKAGE_VERSION=latest

# Turn server
TURN_USERS=webrtcuser:webrtcuser
EXTERNAL_IP=10.10.10.52

# Database
DATABASE_URL= postgresql://postgres:postgres@localhost:5433/nestjs_starter_db

# Redis
REDIS_HOST= localhost
REDIS_PORT= 22376

# JWT
JWT_SECRET=secret
JWT_EXPIRES_IN=90d

# SMTP
MAIL_USER=test
MAIL_PASS=test

# Seed Admin
SUPER_ADMIN_EMAIL=test
SUPER_ADMIN_PASS=test

# AWS S3
AWS_REGION=test
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_S3_BUCKET_NAME=test
```

### Local Development (Hybrid) Setup

Start dependencies (DB + Redis) in Docker, run app locally:

```bash
# Start dependencies
make local-up

# Run app in dev mode
pnpm dev
```

Or use the combined command:

```bash
make local
```

### Full Docker Development

Run entire stack (app + dependencies) in Docker with live reload:

```bash
# Start dev environment
make dev-up

# View logs
make dev-logs

# Stop environment
make dev-stop
```

### Production

```bash
# Build Docker image
make build

# Start production stack
make start

# View logs
make logs

# Stop stack
make stop
```

## 📜 Available Commands

### Makefile Commands

#### Production (Default)

- `make build` - Build Docker image
- `make up` - Start containers (attached)
- `make start` - Start containers (detached)
- `make stop` - Stop containers
- `make restart` - Restart containers
- `make logs` - Show all logs
- `make logs-api` - Show API logs only
- `make clean` - Remove containers, volumes, images
- `make push` - Push image to Docker Hub
- `make ps` - List containers

#### Development (Full Docker)

- `make dev-up` - Start dev environment
- `make dev-stop` - Stop dev environment
- `make dev-logs` - Show dev logs
- `make dev-clean` - Clean dev environment
- `make dev-ps` - List dev containers

#### Local Development (Hybrid)

- `make local-up` - Start DB & Redis only
- `make local-down` - Stop DB & Redis
- `make local` - Start deps + run `pnpm dev`

#### General

- `make images` - List Docker images
- `make volumes` - List Docker volumes
- `make networks` - List Docker networks

### Package.json Scripts

```bash
# Development
pnpm dev              # Start dev server with watch mode
pnpm build            # Build for production
pnpm start            # Run production build

# Code Quality
pnpm lint             # Check linting issues
pnpm lint:fix         # Fix linting issues
pnpm format           # Check formatting
pnpm format:fix       # Fix formatting
pnpm ci:check         # Run all CI checks
pnpm ci:fix           # Fix all CI issues
pnpm commit           # Interactively generate commit message (recommended)

# Database
pnpm prisma           # Prisma CLI
pnpm db:push          # Push schema changes
pnpm db:generate      # Generate Prisma Client
pnpm db:migrate       # Create migration
pnpm db:deploy        # Deploy migrations
pnpm db:studio        # Open Prisma Studio
pnpm db:validate      # Validate schema
pnpm db:format        # Format schema files
```

## 🔄 CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci-cd.yml`):

1. **CI Check** (on PR/push to main)
   - Lint check
   - Format check
   - Build validation

2. **Build & Push** (on merge to main)
   - Build Docker image
   - Push to Docker Hub
   - Tag with `latest`, version, and commit SHA

3. **Deploy** (commented out, ready to configure)
   - Transfer files via SCP
   - SSH into VPS
   - Pull and restart containers

4. **Release** (Automated)
   - Analyzes commits via Semantic Release
   - Bumps version (package.json)
   - Generates CHANGELOG.md
   - Publishes GitHub Release

## 🐳 Docker Architecture

### Production (`compose.yaml`)

- **server** - NestJS API (multi-stage build)
- **db** - PostgreSQL 17
- **redis-master** - Redis primary
- **redis-replica** - Redis replica for HA
- **caddy** - Reverse proxy with auto-HTTPS
- **coturn** - TURN server for WebRTC

### Development (`compose.dev.yaml`)

- **app** - NestJS with hot reload
- **db** - PostgreSQL
- **redis-master** - Redis

### Key Features

- Health checks for all services
- Volume persistence
- Network isolation
- Production-ready reverse proxy

## 📝 Code Quality

### Pre-commit Hooks

Husky triggers `lint-staged` and `commitlint` on commit:

- **Lint Staged**: Runs `eslint` and `prettier` on staged files to ensure code quality before it's committed.
- **Commitlint**: Enforces conventional commit message format.

### Commit Guidelines

We use **Conventional Commits**. The easiest way to commit is:

```bash
pnpm commit
```

This triggers an interactive prompt (`commitizen`) to help you create a valid commit message.
Alternatively, ensure your commits follow the format: `type(scope): subject` (e.g., `feat: add new login page`).

### Linting & Formatting

- **ESLint** - TypeScript-ESLint rules
- **Prettier** - Consistent code style
- **Auto-fix** - Both tools auto-fix on commit

## 🔐 Security Features

- JWT with refresh token rotation
- Bcrypt password hashing
- OTP-based email verification
- Role-based access control
- CORS configuration
- Rate limiting ready

## 📚 API Documentation

Swagger UI available at `/docs` when running the server.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes (hooks will auto-lint/format)
4. Push and create a PR

## 📄 License

UNLICENSED - Private/Commercial use

## 👤 Author

[@shahadathhs](https://github.com/shahadathhs)

---

Built with ❤️ using NestJS, Prisma, and Docker
