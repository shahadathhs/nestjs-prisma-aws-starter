# File Upload & Media System

This project implements a robust, cloud-native file management system using **Amazon S3** for storage and **AWS Elemental MediaConvert** for video processing.

## 🌟 Features

- **S3-backed Storage**: direct upload to AWS S3.
- **Database Tracking**: All files are indexed in PostgreSQL (`FileInstance` model) with metadata (size, mime-type, url).
- **Automatic Organization**: Files are automatically sorted into folders:
  - `images/`: `image/*`
  - `videos/`: `video/*`
  - `audio/`: `audio/*`
  - `documents/`: Everything else
- **Video Merging**: Capability to stitch multiple video files into a single MP4 using AWS MediaConvert.
- **Validation**:
  - Max 5 files per standard upload.
  - Max 500MB per file for video merging.
  - Strict Mime-type checking.

## ⚙️ Configuration

Ensure these variables are set in your `.env`:

```bash
# AWS Credentials
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key

# S3 Configuration
AWS_S3_BUCKET_NAME=your-bucket-name

# MediaConvert (Only if using video merging)
AWS_MEDIACONVERT_ENDPOINT=https://your-endpoint.mediaconvert.us-east-1.amazonaws.com
AWS_MEDIACONVERT_ROLE_ARN=arn:aws:iam::account-id:role/MediaConvertRole
```

### Setup Requirements
1.  **S3 Bucket**: Create a standard S3 bucket. Ensure your IAM user has `s3:PutObject`, `s3:DeleteObject` permissions.
2.  **MediaConvert**:
    *   Create an IAM Role for MediaConvert (trusted entity: `mediaconvert.amazonaws.com`) with permission to access your S3 bucket.
    *   Set `AWS_MEDIACONVERT_ROLE_ARN` to this role's ARN.

## 📂 Code Structure

The implementation is split into two parts:

### 1. Core Library (`src/lib/file`)
This module handles the low-level interactions with AWS.
- **`s3.service.ts`**:
  - `uploadFile(file)`: Uploads buffer to S3 and creates DB record.
  - `deleteFile(id)`: Deletes S3 object and DB record.
  - `createMergeJob(urls)`: Submits a job to MediaConvert.
  - `getFolderByMimeType()`: Logic for bucket organization.

### 2. Upload Feature (`src/main/upload`)
This module exposes the REST API capabilities.
- **`upload.controller.ts`**: Handles HTTP requests, file interception (Multer memory storage), and DTO validation.
- **`upload.service.ts`**: Orchestrates calls to the S3 service.

## 🚀 API Endpoints

### Upload Files
`POST /upload`
- **Content-Type**: `multipart/form-data`
- **Body**: `files` (Array of files)
- **Limits**: Max 5 files.

### Merge Videos
`POST /upload/merge-videos`
- **Content-Type**: `multipart/form-data`
- **Body**: `videos` (Array of video files)
- **Limits**: Max 10 videos, 500MB each.
- **Response**: Returns a Job ID to track progress.

### Get Job Status
`GET /upload/merge-job/:mergeId`
- Returns the current status of the AWS MediaConvert job (e.g., `SUBMITTED`, `COMPLETE`, `ERROR`).

### Management
- `GET /upload`: List uploaded files (paginated).
- `GET /upload/:id`: Get file details.
- `DELETE /upload`: Delete files (Body: `{ "fileIds": ["uuid", ...] }`).

## ⚠️ Important Notes

- **Local Storage**: This system is designed for the cloud. It **does not** support storing files on the local server disk (except for temporary buffering in RAM via `multer.memoryStorage()`).
- **Permissions**: The Application needs `PutObject` on the S3 bucket to work.
