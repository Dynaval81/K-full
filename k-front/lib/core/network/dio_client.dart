import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Singleton Dio instance shared across all services.
/// — Automatically attaches Bearer token from secure storage.
/// — Logs requests/responses in debug builds via PrettyDioLogger.
class DioClient {
  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://knoty.duckdns.org/api/v1',
  );
  static const String _tokenKey = 'auth_token';

  /// Set by AuthController after init. Called when server returns 401
  /// while a real (non-demo) token is present — user was deleted or banned.
  static void Function()? onUnauthorized;

  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — injects Bearer token when present (skips demo tokens)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null && !token.startsWith('demo-')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && !token.startsWith('demo-')) {
            await _storage.delete(key: _tokenKey);
            onUnauthorized?.call();
          }
        }
        handler.next(error);
      },
    ));

    // Pretty request/response logger — debug builds only
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }
  }

  Dio get dio => _dio;

  /// Returns a fresh Dio instance for a different base URL (e.g. Matrix).
  /// Also attaches PrettyDioLogger in debug mode.
  static Dio forBaseUrl(String baseUrl) {
    final d = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 35),
      headers: {'Content-Type': 'application/json'},
    ));
    if (kDebugMode) {
      d.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }
    return d;
  }

  /// Converts any Dio or network error into the standard
  /// `{'success': false, 'error': '...'}` map used throughout ApiService.
  static Map<String, dynamic> handleError(Object e, {String? fallback}) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return {
            'success': false,
            'error': 'Keine Internetverbindung',
            'isOffline': true,
          };
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return {'success': false, 'error': 'Zeitüberschreitung'};
        default:
          final data = e.response?.data;
          if (data is Map) {
            final err = {
              'success': false,
              'error': data['error'] ?? data['message'] ?? fallback ?? 'Request failed',
            };
            if (e.response?.statusCode == 403) {
              if (data['code'] == 'ACCOUNT_BANNED') err['isBanned'] = true;
              if (data['banReason'] != null) err['banReason'] = data['banReason'];
            }
            return err;
          }
          return {'success': false, 'error': fallback ?? 'Request failed'};
      }
    }
    return {'success': false, 'error': fallback ?? e.toString()};
  }
}
