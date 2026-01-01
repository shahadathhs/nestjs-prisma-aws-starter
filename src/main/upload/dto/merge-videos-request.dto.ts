import { ApiProperty } from '@nestjs/swagger';

export class MergeVideosRequestDto {
  @ApiProperty({
    type: 'array',
    items: {
      type: 'string',
      format: 'binary',
    },
    description: 'Video files to merge (2-10 files, max 500MB each)',
    minItems: 2,
    maxItems: 10,
  })
  videos: Express.Multer.File[];
}
