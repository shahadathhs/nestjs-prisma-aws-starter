# Database Backup System

## 🚀 Features

- ✅ **Automated scheduled backups** with cron jobs
- ✅ **Multiple compression formats** (gzip, bzip2, xz)
- ✅ **Local and cloud storage** (AWS S3) support
- ✅ **Automatic retention and cleanup** policies
- ✅ **Health monitoring and email notifications**
- ✅ **Easy restore procedures** with interactive CLI
- ✅ **Docker integration** for production and development
- ✅ **Backup verification and integrity checks**

## 📁 Project Structure

```
├── scripts/
│   ├── backup-database.sh      # Main backup script
│   ├── restore-database.sh     # Database restoration script
│   ├── backup-monitor.sh       # Health monitoring and notifications
│   └── backup.env              # Configuration file
├── Dockerfile.backup           # Backup service container
├── compose.yaml                # Production Docker Compose (includes backup)
├── compose.dev.yaml            # Development Docker Compose (includes backup)
├── Makefile                    # Backup commands (backup-*)
└── docs/BACKUP_SYSTEM.md       # Comprehensive documentation
```

## ⚡ Quick Start

### 1. Configure Environment

Add to your `.env` file:

```bash
# Backup Schedule
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2:00 AM
BACKUP_RETENTION_DAYS=7
BACKUP_COMPRESSION=gzip

# AWS S3 (Optional)
AWS_S3_BUCKET=your-backup-bucket
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Email Notifications (Optional)
NOTIFICATION_EMAIL=admin@example.com
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 2. Start Services

**Production:**

```bash
make start
```

**Development:**

```bash
make dev-up
```

### 3. Use Backup Commands

```bash
# List available backups
make backup-list

# Create manual backup
make backup-manual

# View backup logs
make backup-logs

# Restore from backup (interactive)
make backup-restore
```

## 🔧 Configuration

### Backup Settings

| Setting                 | Default     | Description             |
| ----------------------- | ----------- | ----------------------- |
| `BACKUP_SCHEDULE`       | `0 2 * * *` | Daily at 2:00 AM        |
| `BACKUP_RETENTION_DAYS` | `7`         | Keep backups for 7 days |
| `BACKUP_COMPRESSION`    | `gzip`      | Compression method      |
| `BACKUP_FORMAT`         | `custom`    | PostgreSQL dump format  |

### Storage Options

- **Local Storage**: Docker volumes (`backups-data`, `dev_backups_data`)
- **Cloud Storage**: AWS S3 with automatic upload
- **Compression**: gzip, bzip2, xz support

## 📊 Monitoring

### Health Checks

- Backup count verification
- File size monitoring
- Backup age validation
- Storage capacity checks
- Email alerts for issues

### Notifications

- Backup failures
- Health warnings
- System status reports
- Configurable SMTP settings

## 🔄 Restore Procedures

### Interactive Restore

```bash
make backup-restore
```

### Manual Restore

```bash
# Enter backup container
docker exec -it nestjs_starter_backup bash

# List and restore
/scripts/restore-database.sh list
/scripts/restore-database.sh restore backup_file.dump.gz
```

### S3 Restore

```bash
/scripts/restore-database.sh restore-s3 s3://bucket/path/to/backup.dump.gz
```

## 🐳 Docker Integration

### Production Service

```yaml
backup:
  profiles: ['prod']
  build:
    context: .
    dockerfile: Dockerfile.backup
  environment:
    BACKUP_SCHEDULE: '0 2 * * *'
    RETENTION_DAYS: 7
    AWS_S3_BUCKET: ${AWS_S3_BUCKET}
  volumes:
    - backups-data:/backups
```

### Development Service

```yaml
backup:
  build:
    context: .
    dockerfile: Dockerfile.backup
  environment:
    BACKUP_SCHEDULE: '0 3 * * *' # Different time for dev
    RETENTION_DAYS: 3 # Fewer days in dev
  volumes:
    - dev_backups_data:/backups
```

## 📋 Makefile Commands

| Command               | Description              |
| --------------------- | ------------------------ |
| `make backup-list`    | List available backups   |
| `make backup-manual`  | Create manual backup     |
| `make backup-logs`    | Show backup service logs |
| `make backup-restore` | Interactive restore      |

## 🔒 Security Features

- Environment variable configuration
- Docker network isolation
- S3 encryption support
- No external ports exposed
- Credential rotation support

## 📈 Performance

- Minimal database impact
- Efficient compression
- Parallel S3 uploads
- Optimized for PostgreSQL
- Custom format for fastest restore

## 🛠️ Troubleshooting

### Common Issues

1. **Service not starting**: Check logs with `docker logs nestjs_starter_backup`
2. **Database connection**: Verify with `pg_isready -h db -p 5432`
3. **S3 upload**: Test with `aws s3 ls`
4. **Email notifications**: Check SMTP configuration

### Log Locations

- Backup logs: `/backups/backup.log`
- Cron logs: `/backups/cron.log`
- Monitor logs: `/backups/monitor.log`

## 📚 Documentation

See `docs/BACKUP_SYSTEM.md` for comprehensive documentation including:

- Detailed configuration options
- Advanced troubleshooting
- Security considerations
- Performance optimization
- CI/CD integration
- API reference

## 🔄 Maintenance

### Regular Tasks

- Monitor backup logs weekly
- Verify restore procedures monthly
- Check storage capacity monthly
- Review retention policy quarterly

### Automated Features

- Automatic backup cleanup
- Health monitoring
- Email notifications
- Log rotation
- Storage optimization

---

**Status**: ✅ Production Ready  
**Version**: 1.2.0  
**Last Updated**: 2025-12-31
