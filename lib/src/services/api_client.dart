// lib/src/services/api_client.dart
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;               // <- 명확한 접두사
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String _resolveLocalBaseUrl() {
  const port = 8000;
  if (Platform.isAndroid) return 'http://10.0.2.2:$port';
  return 'http://localhost:$port';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    final env = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final base = env.isNotEmpty ? env : _resolveLocalBaseUrl();

    _dio.options = dio_pkg.BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
    );

    // 공통 인터셉터
    _dio.interceptors.add(
      dio_pkg.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _kAccess);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // 원요청이 refresh 자체면 그냥 종료
          if (e.response?.statusCode != 401 || e.requestOptions.path == _refreshPath) {
            return handler.next(e);
          }

          // 이미 리프레시 시도했는지 플래그로 판단(무한루프 방지)
          final didRetry = e.requestOptions.extra[_kRetried] == true;

          try {
            final ok = await _refreshOnce();
            if (!ok || didRetry) {
              // 리프레시 실패 또는 이미 재시도한 요청이면 토큰 정리 후 그대로 401 전달
              await _clearTokens();
              return handler.next(e);
            }

            // 새 토큰으로 원요청 재시도 (단 1회)
            final newReq = _cloneForRetry(e.requestOptions);
            newReq.extra[_kRetried] = true;
            final resp = await _dio.fetch(newReq);
            return handler.resolve(resp);
          } catch (_) {
            await _clearTokens();
            return handler.next(e);
          }
        },
      ),
    );
  }

  // ====== 상태/상수 ======
  final dio_pkg.Dio _dio = dio_pkg.Dio();
  dio_pkg.Dio get dio => _dio; // 외부 호환용 게터

  final _storage = const FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRetried = '___retried';
  static const _refreshPath = '/auth/refresh'; // 백엔드에 맞게 필요시 변경

  // 동시 다발 refresh 폭주 방지: 진행 중인 1건만 공유
  Future<bool>? _refreshFuture;

  Future<void> init() async {
    // 현재는 생성자에서 모두 설정됨
  }

  // ====== 구현 ======

  Future<bool> _refreshOnce() {
    // 이미 진행 중인 리프레시가 있으면 그 Future 재사용
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final completer = Completer<bool>();
    _refreshFuture = completer.future;

    () async {
      try {
        final rt = await _storage.read(key: _kRefresh);
        if (rt == null || rt.isEmpty) {
          completer.complete(false);
          return;
        }

        // refresh는 인터셉터 영향 줄이려고 별도 인스턴스 사용
        final fresh = dio_pkg.Dio(dio_pkg.BaseOptions(baseUrl: _dio.options.baseUrl));
        final resp = await fresh.post(
          _refreshPath,
          data: {'refresh_token': rt}, // 백엔드 스펙에 맞게 키명 조정
        );

        final newAccess = resp.data['access_token'] as String?;
        final newRefresh = (resp.data['refresh_token'] as String?) ?? rt;
        if (newAccess == null || newAccess.isEmpty) {
          completer.complete(false);
          return;
        }

        await _storage.write(key: _kAccess, value: newAccess);
        await _storage.write(key: _kRefresh, value: newRefresh);
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
      } finally {
        // 완료 후에는 다음 요청을 위해 null로 비움
        _refreshFuture = null;
      }
    }();

    return _refreshFuture!;
  }

  dio_pkg.RequestOptions _cloneForRetry(dio_pkg.RequestOptions r) {
    // headers에 새 토큰 반영
    final headers = Map<String, dynamic>.from(r.headers);
    // 최신 토큰을 바로 읽어 반영
    // (주의: onRequest 인터셉터는 fetch 직전에 다시 붙여주지만, 여기서도 붙여 안전하게)
    return dio_pkg.RequestOptions(
      path: r.path,
      method: r.method,
      data: r.data,
      queryParameters: r.queryParameters,
      headers: headers,
      baseUrl: _dio.options.baseUrl,
      connectTimeout: r.connectTimeout,
      sendTimeout: r.sendTimeout,
      receiveTimeout: r.receiveTimeout,
      responseType: r.responseType,
      contentType: r.contentType,
      followRedirects: r.followRedirects,
      receiveDataWhenStatusError: r.receiveDataWhenStatusError,
      extra: Map<String, dynamic>.from(r.extra),
      validateStatus: r.validateStatus,
      onReceiveProgress: r.onReceiveProgress,
      onSendProgress: r.onSendProgress,
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
