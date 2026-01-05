import { ApiProperty } from '@nestjs/swagger';

class SourceFileDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id: string;

  @ApiProperty({ example: 'video1.mp4' })
  filename: string;

  @ApiProperty({ example: 'https://bucket.s3.amazonaws.com/videos/uuid.mp4' })
  url: string;

  @ApiProperty({ example: 10485760 })
  size: number;
}

class MergeJobDataDto {
  @ApiProperty({ example: '1234567890123-abcdef' })
  jobId: string;

  @ApiProperty({ example: 'https://bucket.s3.amazonaws.com/merged/uuid.mp4' })
  outputUrl: string;

  @ApiProperty({ example: 'SUBMITTED' })
  status: string;

  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  mergeId: string;

  @ApiProperty({ type: [SourceFileDto] })
  sourceFiles: SourceFileDto[];
}

export class MergeVideosResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty()
  data: MergeJobDataDto;

  @ApiProperty({
    example: 'Videos uploaded and merge job created successfully',
  })
  message: string;
}
