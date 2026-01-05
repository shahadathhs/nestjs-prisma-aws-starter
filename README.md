# NestJS + Prisma + AWS Starter

> A production-ready, feature-rich starter template for building scalable backend applications.

[![DeepSource](https://app.deepsource.com/gh/shahadathhs/nestjs-prisma-aws-starter.svg/?label=active+issues&show_trend=true&token=your-token)](https://app.deepsource.com/gh/shahadathhs/nestjs-prisma-aws-starter)
[![License: UNLICENSED](https://img.shields.io/badge/License-UNLICENSED-yellow.svg)](https://opensource.org/licenses/UNLICENSED)

## 📖 Documentation

The documentation has been split into detailed sections:

- **[✨ Features](docs/FEATURES.md)** - Overview of tech stack and capabilities.
- **[🛠️ Setup & Installation](docs/SETUP_INSTALLATION.md)** - Prerequisites, Environment Setup, and Running Locally.
- **[📁 Project Structure](docs/PROJECT_STRUCTURE.md)** - Directory layout explanation.
- **[⌨️ Commands](docs/COMMANDS.md)** - Guide to Makefile commands and npm scripts.
- **[🚀 Deployment](docs/DEPLOYMENT.md)** - Docker architecture, CI/CD pipelines, and Production guides.
- **[☁️ File Upload](docs/FILE_UPLOAD.md)** - S3 storage and Video merging guide.
- **[💾 Backup System](docs/BACKUP_SYSTEM.md)** - Database backup and restore procedures.

## ⚡ Quick Start

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/shahadathhs/nestjs-prisma-aws-starter.git
    cd nestjs-prisma-aws-starter
    ```

2.  **Setup Environment**:
    ```bash
    cp .env.example .env
    # Edit .env with your credentials
    ```

3.  **Run Locally (Hybrid Mode)**:
    ```bash
    make local
    ```
    *Starts DB & Redis in Docker, runs the API natively.*

4.  **Visit API Docs**:
    Open [http://localhost:3000/docs](http://localhost:3000/docs)

## 🤝 Contributing

Contributions are welcome! Please run `pnpm commit` when committing to ensure your commit messages follow our conventions.

---

**Author**: [@shahadathhs](https://github.com/shahadathhs)
