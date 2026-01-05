# Project Structure

```text
├── .github/workflows/     # CI/CD configuration
├── .husky/               # Git hooks
├── backup/              # Database backup system & backup
├── docs/                # Project documentation
├── prisma/
│   ├── schema/          # Split Prisma schema files
│   ├── migrations/      # Database migrations
│   └── generated/       # Generated Prisma Client
├── backup/             # Utility backup (ci-hooks.js)
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
