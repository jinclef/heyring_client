// lib/src/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as gx;
import '../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  final _storage = const FlutterSecureStorage();

  static const _rawBase = "http://10.0.2.2:8000";

  late final Dio dio = Dio(BaseOptions(
    baseUrl: _rawBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    validateStatus: (status) => status != null && status < 500, // 401도 response로 처리
  ))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          if (response.statusCode == 401) {
            // 토큰 삭제
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'refresh_token');

            // AuthController를 통해 로그아웃 처리
            if (gx.Get.isRegistered<AuthController>()) {
              await gx.Get.find<AuthController>().logout();
            }

            // 에러 반환
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: 'Unauthorized',
              ),
            );
          }
          handler.next(response);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            // 토큰 삭제
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'refresh_token');

            // AuthController를 통해 로그아웃 처리
            if (gx.Get.isRegistered<AuthController>()) {
              await gx.Get.find<AuthController>().logout();
            }
          }
          handler.next(e);
        },
      ),
    );
}