# Database Backup System Documentation

## Overview

This project includes a comprehensive automated database backup system for PostgreSQL with the following features:

- **Automated scheduled backups** using cron jobs
- **Compression and encryption** support
- **Local and cloud storage** (AWS S3) support
- **Backup retention and cleanup** policies
- **Health monitoring and notifications**
- **Easy restore procedures**
- **Docker integration** for production and development

## Architecture

### Components

1. **Backup Scripts** (`/backup/`)
   - `backup-database.sh` - Main backup script
   - `restore-database.sh` - Database restoration script
   - `backup-monitor.sh` - Health monitoring and notifications
   - `backup.env` - Configuration file

2. **Docker Service**
   - `Dockerfile.backup` - Backup service container
   - Integrated into `compose.yaml` and `compose.dev.yaml`
   - Runs as a separate container with cron scheduling

3. **Storage**
   - Local storage in Docker volumes (`backups-data`, `dev_backups_data`)
   - Optional AWS S3 cloud storage
   - Automatic compression (gzip, bzip2, xz)

## Quick Start

### 1. Environment Configuration

Add backup configuration to your `.env` file:

```bash
# Backup Schedule (Cron format)
BACKUP_SCHEDULE=0 2 * * *  # Daily at 2:00 AM

# Backup Settings
BACKUP_RETENTION_DAYS=7
BACKUP_COMPRESSION=gzip
BACKUP_FORMAT=custom

# AWS S3 (Optional)
AWS_S3_BUCKET=your-backup-bucket
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1

# Email Notifications (Optional)
NOTIFICATION_EMAIL=admin@example.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 2. Start the Backup Service

**Production:**

```bash
make start  # Starts all services including backup
```

**Development:**

```bash
make dev-up  # Starts dev environment with backup
```

### 3. Manual Operations

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

## Configuration Options

### Backup Settings

| Variable                | Default     | Description                                            |
| ----------------------- | ----------- | ------------------------------------------------------ |
| `BACKUP_SCHEDULE`       | `0 2 * * *` | Cron schedule for automatic backups                    |
| `BACKUP_RETENTION_DAYS` | `7`         | Number of days to keep backups                         |
| `BACKUP_COMPRESSION`    | `gzip`      | Compression method (gzip, bzip2, xz)                   |
| `BACKUP_FORMAT`         | `custom`    | PostgreSQL dump format (custom, directory, tar, plain) |

### Database Connection

| Variable      | Default             | Description       |
| ------------- | ------------------- | ----------------- |
| `DB_HOST`     | `db`                | Database hostname |
| `DB_PORT`     | `5432`              | Database port     |
| `DB_NAME`     | `nestjs_starter_db` | Database name     |
| `DB_USER`     | `postgres`          | Database username |
| `DB_PASSWORD` | `postgres`          | Database password |

### AWS S3 Configuration

| Variable                | Required | Description                               |
| ----------------------- | -------- | ----------------------------------------- |
| `AWS_S3_BUCKET`         | Yes      | S3 bucket name                            |
| `AWS_S3_PREFIX`         | No       | S3 key prefix (default: database-backups) |
| `AWS_REGION`            | No       | AWS region (default: us-east-1)           |
| `AWS_ACCESS_KEY_ID`     | Yes      | AWS access key                            |
| `AWS_SECRET_ACCESS_KEY` | Yes      | AWS secret key                            |

### Email Notifications

| Variable             | Required | Description                     |
| -------------------- | -------- | ------------------------------- |
| `NOTIFICATION_EMAIL` | Yes      | Email address for notifications |
| `SMTP_HOST`          | Yes      | SMTP server hostname            |
| `SMTP_PORT`          | No       | SMTP port (default: 587)        |
| `SMTP_USER`          | Yes      | SMTP username                   |
| `SMTP_PASS`          | Yes      | SMTP password                   |

## Backup Formats

### Custom Format (Recommended)

- **File extension**: `.dump`
- **Compression**: Supported
- **Features**: Full database backup with all objects, selective restore possible
- **Use case**: Production backups, full restores

### Directory Format

- **File extension**: Directory
- **Compression**: Not directly supported
- **Features**: Multiple files, parallel restore possible
- **Use case**: Large databases, partial restores

### Tar Format

- **File extension**: `.tar`
- **Compression**: Supported
- **Features**: Single file archive
- **Use case**: Simple backups, portability

### Plain Format

- **File extension**: `.sql`
- **Compression**: Supported
- **Features**: SQL script, human-readable
- **Use case**: Development, manual inspection

## Scheduling Examples

### Common Cron Schedules

```bash
# Daily at 2:00 AM
BACKUP_SCHEDULE=0 2 * * *

# Every 6 hours
BACKUP_SCHEDULE=0 */6 * * *

# Weekly on Sunday at 3:00 AM
BACKUP_SCHEDULE=0 3 * * 0

# Monthly on 1st at 1:00 AM
BACKUP_SCHEDULE=0 1 1 * *
```

### Cron Format Reference

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, 0 or 7 = Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

## Storage Management

### Local Storage

Backups are stored in Docker volumes:

- **Production**: `backups-data`
- **Development**: `dev_backups_data`

### Cloud Storage (AWS S3)

When AWS credentials are configured, backups are automatically uploaded to S3:

```bash
# S3 path structure
s3://your-bucket/database-backups/
├── nestjs_starter_db_20231231_020000.dump.gz
├── nestjs_starter_db_20231230_020000.dump.gz
└── ...
```

### Retention Policy

- **Production**: Keep 7 days of backups
- **Development**: Keep 3 days of backups
- **Automatic cleanup**: Old backups are removed automatically

## Monitoring and Alerts

### Health Checks

The backup system monitors:

- Backup count (minimum threshold)
- Backup file sizes (maximum threshold)
- Backup age (oldest backup threshold)
- Recent backup activity
- Storage availability

### Alert Types

1. **Critical Alerts**
   - Backup directory missing
   - No backups found
   - Storage full

2. **Warning Alerts**
   - Large backup files
   - Old backups
   - No recent activity

### Notifications

Email notifications are sent for:

- Backup failures
- Health check warnings
- System status reports

## Restore Procedures

### List Available Backups

```bash
make backup-list
```

### Interactive Restore

```bash
make backup-restore
```

### Manual Restore

```bash
# Enter backup container
docker exec -it nestjs_starter_backup bash

# List backups
/backup/restore-database.sh list

# Restore specific backup
/backup/restore-database.sh restore /backups/backup_file.dump.gz

# Restore from S3
/backup/restore-database.sh restore-s3 s3://bucket/path/to/backup.dump.gz
```

### Force Restore

To replace the existing database:

```bash
FORCE_RESTORE=true /backup/restore-database.sh restore backup_file.dump.gz
```

## Troubleshooting

### Common Issues

1. **Backup Service Not Starting**

   ```bash
   # Check logs
   docker logs nestjs_starter_backup

   # Verify environment variables
   docker exec nestjs_starter_backup env | grep BACKUP
   ```

2. **Database Connection Failed**

   ```bash
   # Test database connectivity
   docker exec nestjs_starter_backup pg_isready -h db -p 5432 -U postgres
   ```

3. **S3 Upload Failed**

   ```bash
   # Check AWS credentials
   docker exec nestjs_starter_backup aws s3 ls

   # Test S3 access
   docker exec nestjs_starter_backup aws s3 cp test.txt s3://your-bucket/
   ```

4. **Email Notifications Not Working**
   ```bash
   # Test email configuration
   docker exec nestjs_starter_backup /backup/backup-monitor.sh check
   ```

### Log Locations

- **Backup/Cron logs**: `/var/log/backup/cron.log`
- **Monitor logs**: `/var/log/backup/monitor.log`

### Manual Backup Testing

```bash
# Test backup script manually
docker exec nestjs_starter_backup /backup/backup-database.sh

# Verify backup was created
docker exec nestjs_starter_backup ls -la /backups/

# Test restore
docker exec nestjs_starter_backup /backup/restore-database.sh list
```

## Security Considerations

### Database Credentials

- Database passwords are stored in environment variables
- Use strong, unique passwords
- Rotate credentials regularly

### Backup Security

- Backups contain all database data
- Enable S3 encryption for cloud storage
- Consider backup encryption for sensitive data

### Network Security

- Backup service runs in isolated Docker network
- Only database access is required
- No external ports exposed

## Performance Impact

### Backup Performance

- **Custom format**: Fastest backup and restore
- **Compression**: Reduces storage size, increases CPU usage
- **Network**: S3 upload time depends on file size and bandwidth

### Database Impact

- Backups use PostgreSQL's pg_dump
- Minimal performance impact during backup
- Consider off-peak scheduling for large databases

## Maintenance

### Regular Tasks

1. **Monitor backup logs** weekly
2. **Verify restore procedures** monthly
3. **Check storage capacity** monthly
4. **Update credentials** quarterly
5. **Review retention policy** quarterly

### Capacity Planning

- Monitor backup sizes over time
- Plan for storage growth
- Consider archive strategies for long-term retention

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Backup Test
on:
  schedule:
    - cron: '0 3 * * *' # Daily at 3:00 AM

jobs:
  test-backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Start services
        run: make dev-up
      - name: Test backup
        run: make backup-manual
      - name: Verify backup
        run: make backup-list
      - name: Cleanup
        run: make dev-clean
```

## API Reference

### Backup Script Commands

```bash
# Create backup
./backup-database.sh

# With custom settings
DB_HOST=localhost DB_PORT=5432 ./backup-database.sh
```

### Restore Script Commands

```bash
# List backups
./restore-database.sh list

# Restore backup
./restore-database.sh restore backup_file.dump.gz

# Restore from S3
./restore-database.sh restore-s3 s3://bucket/path/to/backup.dump.gz
```

### Monitor Script Commands

```bash
# Health check
./backup-monitor.sh check

# Generate report
./backup-monitor.sh report
```

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review container logs
3. Verify configuration
4. Test manual procedures

## Version History

- **v1.0.0**: Initial backup system implementation
- **v1.1.0**: Added monitoring and notifications
- **v1.2.0**: Enhanced S3 integration and compression options
