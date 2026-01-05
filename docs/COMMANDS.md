# Available Commands

## Makefile Commands

### Production (Default)

| Command | Description |
|---------|-------------|
| `make build` | Build Docker image |
| `make up` | Start containers (attached) |
| `make start` | Start containers (detached) |
| `make stop` | Stop containers |
| `make restart` | Restart containers |
| `make logs` | Show all logs |
| `make logs-api` | Show API logs only |
| `make clean` | Remove containers, volumes, images |
| `make push` | Push image to Docker Hub |
| `make ps` | List containers |

### Development (Full Docker)

| Command | Description |
|---------|-------------|
| `make dev-up` | Start dev environment |
| `make dev-stop` | Stop dev environment |
| `make dev-logs` | Show dev logs |
| `make dev-clean` | Clean dev environment |
| `make dev-ps` | List dev containers |

### Local Development (Hybrid)

| Command | Description |
|---------|-------------|
| `make local-up` | Start DB & Redis only |
| `make local-down` | Stop DB & Redis |
| `make local` | Start deps + run `pnpm dev` |

### Database Backup

| Command | Description |
|---------|-------------|
| `make backup-list` | List available backups |
| `make backup-manual` | Trigger immediate backup |
| `make backup-restore` | Interactive restore wizard |
| `make backup-logs` | View backup service logs |

## NPM Scripts

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
