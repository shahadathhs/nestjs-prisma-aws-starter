import { Global, Module } from '@nestjs/common';
import { AuthUtilsService } from './services/auth-utils.service';
import { UtilsService } from './services/utils.service';

@Global()
@Module({
  providers: [UtilsService, AuthUtilsService],
  exports: [UtilsService, AuthUtilsService],
})
export class UtilsModule {}
