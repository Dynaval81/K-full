import 'dart:async';
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
  static const String _refreshTokenKey = 'refresh_token';

  /// Set by AuthController after init. Called when server returns 401
  /// and token refresh has failed — user was deleted, banned, or session expired.
  static void Function()? onUnauthorized;

  // ── Refresh state (singleton-safe) ────────────────────────────────
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

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
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        final token = await _storage.read(key: _tokenKey);

        // Skip demo tokens or missing token — just propagate
        if (token == null || token.startsWith('demo-')) {
          handler.next(error);
          return;
        }

        // Prevent infinite loop if we already retried this request
        if (error.requestOptions.extra['_retried'] == true) {
          await _storage.delete(key: _tokenKey);
          await _storage.delete(key: _refreshTokenKey);
          onUnauthorized?.call();
          handler.next(error);
          return;
        }

        // If a refresh is already in progress, queue this request
        if (_isRefreshing) {
          final completer = Completer<String?>();
          _refreshQueue.add(completer);
          final newToken = await completer.future;
          if (newToken != null) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            opts.extra['_retried'] = true;
            try {
              handler.resolve(await _dio.fetch(opts));
            } catch (_) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
          return;
        }

        _isRefreshing = true;
        try {
          final refreshToken = await _storage.read(key: _refreshTokenKey);
          if (refreshToken == null) throw Exception('No refresh token stored');

          final refreshDio = Dio(BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ));

          final res = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = res.data['data']['accessToken'] as String;
          final newRefreshToken = res.data['data']['refreshToken'] as String;

          await _storage.write(key: _tokenKey, value: newAccessToken);
          await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

          // Resume queued requests
          for (final c in _refreshQueue) {
            c.complete(newAccessToken);
          }
          _refreshQueue.clear();

          // Retry original request
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          opts.extra['_retried'] = true;
          handler.resolve(await _dio.fetch(opts));
        } catch (_) {
          for (final c in _refreshQueue) {
            c.complete(null);
          }
          _refreshQueue.clear();
          await _storage.delete(key: _tokenKey);
          await _storage.delete(key: _refreshTokenKey);
          onUnauthorized?.call();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
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
