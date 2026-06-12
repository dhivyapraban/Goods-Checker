import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import '../../models/audit_damage_result.dart';
import '../storage_service.dart';

class AuditDamageService {
  AuditDamageService({Dio? dio, StorageService? storageService})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(
                seconds: 120,
              ), // HF API can be slow
              sendTimeout: const Duration(seconds: 60),
            ),
          ),
      _storageService = storageService ?? StorageService();

  final Dio _dio;
  final StorageService _storageService;

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<AuditDamageResult> auditDamage({
    required String boxId,
    required Uint8List refViewA,
    required Uint8List refViewB,
    required Uint8List curViewA,
    required Uint8List curViewB,
  }) async {
    final token = await _storageService.getToken();

    final form = FormData.fromMap({
      'box_id': boxId,
      'timestamp': DateTime.now().toIso8601String(),
      'ref_view_A': MultipartFile.fromBytes(
        refViewA,
        filename: 'ref_view_A.jpg',
      ),
      'ref_view_B': MultipartFile.fromBytes(
        refViewB,
        filename: 'ref_view_B.jpg',
      ),
      'cur_view_A': MultipartFile.fromBytes(
        curViewA,
        filename: 'cur_view_A.jpg',
      ),
      'cur_view_B': MultipartFile.fromBytes(
        curViewB,
        filename: 'cur_view_B.jpg',
      ),
    });

    // Retry logic for transient network failures
    Exception? lastException;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        if (kDebugMode) {
          print('Audit API retry attempt $attempt after ${_retryDelay.inSeconds}s delay');
        }
        await Future.delayed(_retryDelay);
      }

      try {
        final response = await _dio.post(
          ApiConfig.auditDamage,
          data: form,
          options: Options(
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            contentType: 'multipart/form-data',
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

        final data = response.data;
        if (data is Map<String, dynamic>) {
          return AuditDamageResult.fromJson(data);
        }

        throw StateError('Unexpected response from server');
      } on DioException catch (e) {
        lastException = e;
        
        // Only retry on connection/socket errors, not on 4xx/5xx responses
        final isRetryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            (e.error is SocketException);

        if (!isRetryable || attempt >= _maxRetries) {
          if (kDebugMode) {
            print('Audit damage failed: ${e.response?.statusCode} ${e.message}');
            print('Error type: ${e.type}');
            if (e.response?.data != null) {
              print('Body: ${e.response?.data}');
            }
            if (e.error != null) {
              print('Error: ${e.error}');
            }
          }

          final status = e.response?.statusCode;

          // Handle connection errors
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.error is SocketException) {
            throw StateError(
              'Cannot connect to audit service. Check your internet connection.',
            );
          }

          if (e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            throw StateError(
              'Audit service timed out. The service may be busy - please try again.',
            );
          }

          // Friendly handling for common API-tier failures
          if (status == 429) {
            throw StateError(
              'API limit reached. Please wait a moment and try again.',
            );
          }
          if (status == 502 || status == 503 || status == 504) {
            throw StateError(
              'Audit service is temporarily unavailable. Please try again shortly.',
            );
          }

          // Try to surface backend validation errors.
          final body = e.response?.data;
          if (body is Map<String, dynamic>) {
            final message = body['message'] ?? body['reason'] ?? body['error'];
            final requestId = body['request_id'];
            if (message != null) {
              final msg = requestId == null
                  ? message.toString()
                  : '${message.toString()} (request: ${requestId.toString()})';
              throw StateError(msg);
            }
          }

          rethrow;
        }
        
        if (kDebugMode) {
          print('Retryable error on attempt $attempt: ${e.type}');
        }
      }
    }

    // Should not reach here, but just in case
    if (lastException != null) {
      throw lastException;
    }
    throw StateError('Audit request failed after retries');
  }
}
