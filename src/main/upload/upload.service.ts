import { PaginationDto } from '@/common/dto/pagination.dto';
import {
  successPaginatedResponse,
  successResponse,
  TPaginatedResponse,
  TResponse,
} from '@/common/utils/response.util';
import { AppError } from '@/core/error/handle-error.app';
import { HandleError } from '@/core/error/handle-error.decorator';
import { S3Service } from '@/lib/file/services/s3.service';
import { PrismaService } from '@/lib/prisma/prisma.service';
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
  ) {}

  @HandleError('Failed to upload file(s)', 'File')
  async uploadFiles(files: Express.Multer.File[]): Promise<TResponse<any>> {
    if (!files || files.length === 0) {
      throw new AppError(404, 'No file(s) uploaded');
    }

    if (files.length > 5) {
      throw new AppError(400, 'You can upload a maximum of 5 files');
    }

    // Parallelize uploads
    const results = await Promise.all(
      files.map((file) => this.s3.uploadFile(file)),
    );

    return successResponse(
      {
        files: results,
        count: results.length,
      },
      'Files uploaded successfully',
    );
  }

  @HandleError('Failed to delete files', 'File')
  async deleteFiles(fileIds: string[]): Promise<TResponse<any>> {
    if (!fileIds?.length) throw new AppError(400, 'No file IDs provided');

    const files = await this.prisma.client.fileInstance.findMany({
      where: { id: { in: fileIds } },
    });

    if (!files.length) throw new AppError(404, 'Files not found');

    // Parallelize deletes
    await Promise.all(files.map((f) => this.s3.deleteFile(f.id)));

    return successResponse(
      { files, count: files.length },
      'Files deleted successfully',
    );
  }

  @HandleError('Failed to get files', 'File')
  async getFiles(pg: PaginationDto): Promise<TPaginatedResponse<any>> {
    const page = pg.page && +pg.page > 0 ? +pg.page : 1;
    const limit = pg.limit && +pg.limit > 0 ? +pg.limit : 10;
    const skip = (page - 1) * limit;

    const [files, total] = await this.prisma.client.$transaction([
      this.prisma.client.fileInstance.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.client.fileInstance.count(),
    ]);

    return successPaginatedResponse(
      files,
      { page, limit, total },
      'Files found',
    );
  }

  @HandleError('Failed to get file', 'File')
  async getFileById(id: string): Promise<TResponse<any>> {
    const file = await this.prisma.client.fileInstance.findUnique({
      where: { id },
    });

    if (!file) throw new AppError(404, 'File not found');

    return successResponse(file, 'File found');
  }

  @HandleError('Failed to merge videos', 'File')
  async mergeVideos(files: Express.Multer.File[]): Promise<TResponse<any>> {
    if (!files || files.length === 0) {
      throw new AppError(400, 'No files provided');
    }

    if (files.length < 2) {
      throw new AppError(400, 'At least 2 videos are required for merging');
    }

    if (files.length > 10) {
      throw new AppError(400, 'You can merge a maximum of 10 videos at once');
    }

    // Validate all files are videos
    const invalidFiles = files.filter(
      (file) => !file.mimetype.startsWith('video/'),
    );

    if (invalidFiles.length > 0) {
      throw new AppError(
        400,
        `Invalid file types detected. Only video files are allowed. Found: ${invalidFiles.map((f) => f.mimetype).join(', ')}`,
      );
    }

    // Upload all videos to S3 in parallel
    const uploadedFiles = await Promise.all(
      files.map((file) => this.s3.uploadFile(file)),
    );

    // Extract video URLs
    const videoUrls = uploadedFiles.map((file) => file.url);

    this.logger.log(
      `Uploaded ${uploadedFiles.length} videos for merging.`,
      videoUrls,
    );

    // Create merge job in AWS MediaConvert
    const { jobId, outputUrl } = await this.s3.createMergeJob(videoUrls);

    // Save the merge job to database for tracking
    const mergeRecord = await this.prisma.client.videoMergeJob.create({
      data: {
        jobId,
        outputUrl,
        status: 'SUBMITTED',
        sourceFileIds: uploadedFiles.map((f) => f.id),
      },
    });

    this.logger.log(`Created merge job with ID: ${jobId}`, {
      mergeRecordId: mergeRecord.id,
      outputUrl,
    });

    return successResponse(
      {
        jobId,
        outputUrl,
        status: 'SUBMITTED',
        mergeId: mergeRecord.id,
        sourceFiles: uploadedFiles.map((f) => ({
          id: f.id,
          filename: f.originalFilename,
          url: f.url,
          size: f.size,
        })),
        count: uploadedFiles.length,
      },
      'Videos uploaded and merge job created successfully',
    );
  }

  @HandleError('Failed to check merge job status', 'File')
  async getMergeJobStatus(mergeId: string): Promise<TResponse<any>> {
    const mergeJob = await this.prisma.client.videoMergeJob.findUnique({
      where: { id: mergeId },
    });

    if (!mergeJob) {
      throw new AppError(404, 'Merge job not found');
    }

    const jobId = mergeJob.jobId;

    const status = await this.s3.getMergeJobStatus(jobId);

    return successResponse(
      {
        mergeId,
        jobId,
        status,
        outputUrl: mergeJob.outputUrl,
      },
      'Merge job status retrieved successfully',
    );
  }
}
