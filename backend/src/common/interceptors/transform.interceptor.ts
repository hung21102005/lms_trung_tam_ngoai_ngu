import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiResponse } from '../interfaces/api-response.interface.js';

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    const statusCode = response.statusCode;

    return next.handle().pipe(
      map((resData) => {
        // If response already matches standard structure, return as is
        if (resData && typeof resData === 'object' && 'success' in resData && 'statusCode' in resData) {
          return resData;
        }

        let message = 'Thao tác thành công.';
        let data = resData;

        // Extract custom message if returned as { message, data }
        if (resData && typeof resData === 'object' && 'message' in resData && 'data' in resData) {
          message = resData.message;
          data = resData.data;
        }

        return {
          success: true,
          statusCode,
          message,
          data: data ?? null,
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}
