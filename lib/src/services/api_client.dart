// lib/src/services/api_client.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as gx;
import '../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  final _storage = const FlutterSecureStorage();

  // 플랫폼별 baseUrl 설정
  static String get _rawBase {
    if (Platform.isIOS) {
      // iOS 시뮬레이터는 localhost 사용
      // 실기기 테스트 시에는 실제 서버 IP로 변경 필요
      return "http://localhost:8000";
      // 실기기 테스트 시: "http://192.168.x.x:8000"
    } else if (Platform.isAndroid) {
      // Android 에뮬레이터는 10.0.2.2 사용
      return "http://10.0.2.2:8000";
    } else {
      // Web 또는 기타
      return "http://localhost:8000";
    }
  }

  bool _isRefreshing = false;

  late final Dio dio = Dio(BaseOptions(
    baseUrl: _rawBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // 로그아웃 엔드포인트는 401이 나도 무시
          if (response.statusCode == 401 &&
              response.requestOptions.path.contains('/auth/logout')) {
            return handler.next(response);
          }

          // 401 처리
          if (response.statusCode == 401 &&
              !response.requestOptions.path.contains('/auth/refresh') &&
              !response.requestOptions.path.contains('/auth/login')) {

            if (_isRefreshing) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            _isRefreshing = true;

            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken == null || refreshToken.isEmpty) {
                throw Exception('No refresh token');
              }

              final refreshResponse = await dio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
                options: Options(
                  headers: {'Authorization': 'Bearer $refreshToken'},
                ),
              );

              if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                final newAccessToken = refreshResponse.data['access_token'] as String?;
                final newRefreshToken = refreshResponse.data['refresh_token'] as String?;

                if (newAccessToken != null) {
                  await _storage.write(key: 'auth_token', value: newAccessToken);
                  if (newRefreshToken != null) {
                    await _storage.write(key: 'refresh_token', value: newRefreshToken);
                  }

                  response.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                  final retryResponse = await dio.fetch(response.requestOptions);
                  _isRefreshing = false;
                  return handler.resolve(retryResponse);
                }
              }

              throw Exception('Refresh failed');
            } catch (e) {
              _isRefreshing = false;
              await _handleLogout();

              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          } else if (response.statusCode == 401) {
            await _handleLogout();

            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          // 로그아웃 엔드포인트 에러는 무시
          if (error.requestOptions.path.contains('/auth/logout')) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401) {
            await _handleLogout();
          }

          handler.next(error);
        },
      ),
    );

  Future<void> _handleLogout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');

    if (gx.Get.isRegistered<AuthController>()) {
      await gx.Get.find<AuthController>().logout();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (gx.Get.currentRoute != Routes.login) {
        gx.Get.offAllNamed(Routes.login);
      }
    });
  }
}