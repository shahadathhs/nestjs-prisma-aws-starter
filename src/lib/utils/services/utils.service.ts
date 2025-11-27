import { Injectable } from '@nestjs/common';
import { ClassConstructor, plainToInstance } from 'class-transformer';

@Injectable()
export class UtilsService {
  sanitizedResponse(dto: any, data: any) {
    return plainToInstance(dto, data, { excludeExtraneousValues: true });
  }

  sanitizeWithRelations<T>(
    dto: ClassConstructor<any>,
    entity: Record<string, any>,
  ): T {
    // Separate scalar fields from relations
    const scalars: Record<string, any> = {};
    const relations: Record<string, any> = {};

    for (const key in entity) {
      const value = entity[key];
      if (
        value !== null &&
        typeof value === 'object' &&
        !Array.isArray(value)
      ) {
        // This is either a relation object or a Prisma _count
        relations[key] = value;
      } else if (Array.isArray(value)) {
        // Relation arrays
        relations[key] = value;
      } else {
        // Scalar value
        scalars[key] = value;
      }
    }

    // Sanitize only scalars
    const sanitizedBase = this.sanitizedResponse(dto, scalars);

    // Merge sanitized scalars back with untouched relations
    return {
      ...sanitizedBase,
      ...relations,
    } as T;
  }

  removeDuplicateIds(ids: string[]) {
    return Array.from(new Set(ids));
  }

  safeParseJson<T>(value: any, fallback: T): T {
    try {
      if (typeof value === 'string') {
        return JSON.parse(value);
      }
      return value ?? fallback;
    } catch {
      return fallback;
    }
  }
}
