import { ENVEnum } from '@/common/enum/env.enum';
import { AppError } from '@/core/error/handle-error.app';
import { PrismaService } from '@/lib/prisma/prisma.service';
import {
  AacCodingMode,
  AudioCodec,
  AudioDefaultSelection,
  CreateJobCommand,
  GetJobCommand,
  H264RateControlMode,
  H264SceneChangeDetect,
  MediaConvertClient,
  VideoCodec,
} from '@aws-sdk/client-mediaconvert';
import {
  DeleteObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileType } from '@prisma';
import * as fs from 'fs';
import path from 'node:path';
import { v4 as uuid } from 'uuid';

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);

  private s3: S3Client;
  private mediaConvert: MediaConvertClient;

  private readonly AWS_S3_BUCKET_NAME: string;
  private readonly AWS_REGION: string;
  private readonly AWS_MEDIACONVERT_ENDPOINT: string;
  private readonly AWS_MEDIACONVERT_ROLE_ARN: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.AWS_REGION = this.configService.getOrThrow(ENVEnum.AWS_REGION);
    this.AWS_S3_BUCKET_NAME = this.configService.getOrThrow(
      ENVEnum.AWS_S3_BUCKET_NAME,
    );

    this.AWS_MEDIACONVERT_ENDPOINT = this.configService.getOrThrow(
      ENVEnum.AWS_MEDIACONVERT_ENDPOINT,
    );

    this.AWS_MEDIACONVERT_ROLE_ARN = this.configService.getOrThrow(
      ENVEnum.AWS_MEDIACONVERT_ROLE_ARN,
    );

    this.s3 = new S3Client({
      region: this.AWS_REGION,
      credentials: {
        accessKeyId: this.configService.getOrThrow(ENVEnum.AWS_ACCESS_KEY_ID),
        secretAccessKey: this.configService.getOrThrow(
          ENVEnum.AWS_SECRET_ACCESS_KEY,
        ),
      },
    });

    this.mediaConvert = new MediaConvertClient({
      region: this.AWS_REGION,
      endpoint: this.AWS_MEDIACONVERT_ENDPOINT,
      credentials: {
        accessKeyId: this.configService.getOrThrow(ENVEnum.AWS_ACCESS_KEY_ID),
        secretAccessKey: this.configService.getOrThrow(
          ENVEnum.AWS_SECRET_ACCESS_KEY,
        ),
      },
    });
  }

  private buildS3Url(key: string): string {
    return `https://${this.AWS_S3_BUCKET_NAME}.s3.${this.AWS_REGION}.amazonaws.com/${key}`;
  }

  private async uploadBuffer(
    key: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<string> {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.AWS_S3_BUCKET_NAME,
        Key: key,
        Body: buffer,
        ContentType: mimeType,
      }),
    );

    return this.buildS3Url(key);
  }

  private async deleteObject(key: string) {
    await this.s3.send(
      new DeleteObjectCommand({
        Bucket: this.AWS_S3_BUCKET_NAME,
        Key: key,
      }),
    );
  }

  async uploadFile(file: Express.Multer.File) {
    const fileExt = file.originalname.split('.').pop();
    const folder = this.getFolderByMimeType(file.mimetype);
    const uniqueFileName = `${uuid()}.${fileExt}`;
    const s3Key = `${folder}/${uniqueFileName}`;

    // Upload to S3
    const fileUrl = await this.uploadBuffer(s3Key, file.buffer, file.mimetype);

    // Save record in database
    const fileRecord = await this.prisma.client.fileInstance.create({
      data: {
        filename: uniqueFileName,
        originalFilename: file.originalname,
        path: s3Key,
        url: fileUrl,
        fileType: this.getFileType(file.mimetype),
        mimeType: file.mimetype,
        size: file.size,
      },
    });

    return fileRecord;
  }

  async deleteFile(id: string) {
    const file = await this.prisma.client.fileInstance.findUnique({
      where: { id },
    });

    if (!file) {
      throw new AppError(404, 'File not found');
    }

    await this.deleteObject(file.path);

    await this.prisma.client.fileInstance.delete({
      where: { id },
    });
  }

  async uploadFileByPath(filePath: string, originalName?: string) {
    if (!fs.existsSync(filePath)) {
      throw new AppError(404, `File not found: ${filePath}`);
    }

    const fileBuffer = fs.readFileSync(filePath);
    const fileExt = path.extname(originalName || filePath).slice(1);
    const mimeType = this.getMimeTypeFromExtension(fileExt);

    const folder = this.getFolderByMimeType(mimeType);
    const uniqueFileName = `${uuid()}.${fileExt}`;
    const s3Key = `${folder}/${uniqueFileName}`;

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: this.AWS_S3_BUCKET_NAME,
      Key: s3Key,
      Body: fileBuffer,
      ContentType: mimeType,
    });

    await this.s3.send(command);

    // Construct file URL
    const fileUrl = this.buildS3Url(s3Key);

    // Save record in DB
    const fileRecord = await this.prisma.client.fileInstance.create({
      data: {
        filename: uniqueFileName,
        originalFilename: originalName || path.basename(filePath),
        path: s3Key,
        url: fileUrl,
        fileType: this.getFileType(mimeType),
        mimeType,
        size: fileBuffer.length,
      },
    });

    // Delete file from disk
    fs.unlinkSync(filePath);

    return fileRecord;
  }

  async createMergeJob(
    videoUrls: string[],
  ): Promise<{ jobId: string; outputUrl: string }> {
    if (!videoUrls || videoUrls.length < 2) {
      throw new AppError(400, 'At least 2 videos are required for merging.');
    }

    const outputName = `merged-${uuid()}.mp4`;
    const s3Destination = `s3://${this.AWS_S3_BUCKET_NAME}/merged/`;

    // Build Inputs (each one gets one AudioSelector)
    const inputs = videoUrls.map((url, index) => ({
      FileInput: url,
      InputClippings: [], // REQUIRED for concatenation
      AudioSelectors: {
        [`AudioSelector${index}`]: {
          DefaultSelection: AudioDefaultSelection.DEFAULT,
        },
      },
      VideoSelector: {},
    }));

    // AUDIO: Use the FIRST input's audio track
    const audioDescriptions = [
      {
        AudioSourceName: 'AudioSelector0',
        CodecSettings: {
          Codec: AudioCodec.AAC,
          AacSettings: {
            Bitrate: 96000,
            CodingMode: AacCodingMode.CODING_MODE_2_0,
            SampleRate: 48000,
          },
        },
      },
    ];

    // VIDEO settings
    const videoDescription = {
      CodecSettings: {
        Codec: VideoCodec.H_264,
        H264Settings: {
          RateControlMode: H264RateControlMode.QVBR,
          MaxBitrate: 5000000,
          SceneChangeDetect: H264SceneChangeDetect.TRANSITION_DETECTION,
        },
      },
    };

    // Final MediaConvert Job
    const command = new CreateJobCommand({
      Role: this.AWS_MEDIACONVERT_ROLE_ARN,
      Settings: {
        Inputs: inputs,
        OutputGroups: [
          {
            OutputGroupSettings: {
              Type: 'FILE_GROUP_SETTINGS',
              FileGroupSettings: { Destination: s3Destination },
            },
            Outputs: [
              {
                NameModifier: outputName.replace('.mp4', ''),
                ContainerSettings: { Container: 'MP4' },
                VideoDescription: videoDescription,
                AudioDescriptions: audioDescriptions,
              },
            ],
          },
        ],
      },
    });

    const result = await this.mediaConvert.send(command);

    if (!result.Job?.Id) {
      this.logger.error('Failed to create merge job', result);
      throw new AppError(500, 'Failed to create merge job');
    }

    // Get the NameModifier AWS actually used
    const nameModifier =
      result.Job.Settings?.OutputGroups?.[0]?.Outputs?.[0]?.NameModifier;

    if (!nameModifier) {
      throw new AppError(
        500,
        'Failed to get NameModifier from AWS MediaConvert job',
      );
    }

    // First input base name
    const firstInputBase =
      videoUrls[0].split('/').pop()?.replace('.mp4', '') || '';

    // Build the exact output URL
    const outputUrl = `https://${this.AWS_S3_BUCKET_NAME}.s3.${this.AWS_REGION}.amazonaws.com/merged/${firstInputBase}${nameModifier}.mp4`;

    return {
      jobId: result.Job.Id,
      outputUrl,
    };
  }

  async createMergeTwoVideos(
    video1: string,
    video2: string,
  ): Promise<{ jobId: string; outputUrl: string }> {
    const outputName = `merged-${uuid()}`;
    const s3Destination = `s3://${this.AWS_S3_BUCKET_NAME}/merged/`;

    const video1Filename = video1.split('/').pop()?.replace('.mp4', '') || '';

    const inputs = [
      {
        FileInput: video1,
        AudioSelectors: {
          'Audio Selector 1': {
            DefaultSelection: AudioDefaultSelection.DEFAULT,
          },
        },
        VideoSelector: {},
      },
      {
        FileInput: video2,
        AudioSelectors: {
          'Audio Selector 2': {
            DefaultSelection: AudioDefaultSelection.DEFAULT,
          },
        },
        VideoSelector: {},
      },
    ];

    const audioDescriptions = [
      {
        AudioSourceName: 'Audio Selector 1',
        CodecSettings: {
          Codec: AudioCodec.AAC,
          AacSettings: {
            Bitrate: 96000,
            CodingMode: AacCodingMode.CODING_MODE_2_0,
            SampleRate: 48000,
          },
        },
      },
    ];

    const videoDescription = {
      CodecSettings: {
        Codec: VideoCodec.H_264,
        H264Settings: {
          RateControlMode: H264RateControlMode.QVBR,
          MaxBitrate: 5000000,
          SceneChangeDetect: H264SceneChangeDetect.TRANSITION_DETECTION,
        },
      },
    };

    const command = new CreateJobCommand({
      Role: this.AWS_MEDIACONVERT_ROLE_ARN,
      Settings: {
        Inputs: inputs as any,
        OutputGroups: [
          {
            OutputGroupSettings: {
              Type: 'FILE_GROUP_SETTINGS',
              FileGroupSettings: { Destination: s3Destination },
            },
            Outputs: [
              {
                ContainerSettings: { Container: 'MP4' },
                NameModifier: outputName.replace('.mp4', ''),
                VideoDescription: videoDescription,
                AudioDescriptions: audioDescriptions,
              },
            ],
          },
        ],
      },
    });

    const result = await this.mediaConvert.send(command);

    if (!result.Job?.Id) {
      this.logger.error('Failed to create merge job', result);
      throw new AppError(500, 'Failed to create merge job');
    }

    const actualOutputFilename = `${video1Filename}${outputName}.mp4`;

    return {
      jobId: result.Job.Id,
      outputUrl: `https://${this.AWS_S3_BUCKET_NAME}.s3.${this.AWS_REGION}.amazonaws.com/merged/${actualOutputFilename}`,
    };
  }

  async getMergeJobStatus(jobId: string): Promise<any> {
    const command = new GetJobCommand({ Id: jobId });
    const result = await this.mediaConvert.send(command);

    if (!result.Job || !result.Job.Status) {
      this.logger.error('Failed to get job status', result);
      throw new AppError(500, 'Failed to get job status');
    }

    return {
      status: result.Job?.Status,
      job: result.Job,
      result,
    };
  }

  getFolderByMimeType(mimeType: string): string {
    if (mimeType.startsWith('image/')) return 'images';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('video/')) return 'videos';
    return 'documents';
  }

  getFileType(mimeType: string): FileType {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType === 'application/pdf') return 'document';
    return 'any';
  }

  getMimeTypeFromExtension(ext: string): string {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'ogg':
        return 'video/ogg';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
