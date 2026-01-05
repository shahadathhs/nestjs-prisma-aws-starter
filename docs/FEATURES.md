# Features

## Core Stack

- **NestJS** - Progressive Node.js framework
- **Prisma ORM** - Type-safe database access with split schema architecture
- **PostgreSQL** - Primary database
- **Redis** - Caching and queue management
- **TypeScript** - Full type safety
- **Docker** - Production and development containers

## Authentication & Security

- JWT-based authentication with refresh tokens
- Email verification via OTP
- Password reset flow
- Role-based access control (SUPER_ADMIN, ADMIN, USER)
- Bcrypt password hashing
- Passport.js integration

## Real-time Features

- WebSocket Gateway with Socket.IO
- Private messaging system
- Conversation management (archive, block, delete)
- WebRTC support with TURN server (coturn)
- Live reload in development

## File Management

- File upload with Multer
- AWS S3 integration
- AWS Media Convert integration
- Configurable upload limits (up to 500MB via Caddy)

## Background Jobs

- BullMQ job queues
- Event-driven architecture with EventEmitter
- Scheduled tasks with @nestjs/schedule

## Developer Experience

- **Husky** - Git hooks made easy
- **Commitizen** - Interactive commit generator
- **Commitlint** - Lint commit messages
- **Semantic Release** - Automated versioning and changelogs
- **Lint Staged** - Run linters on staged files
- **ESLint + Prettier** - Automated linting and formatting
- **Swagger** - API documentation
- **Split Prisma Schema** - Organized database models
