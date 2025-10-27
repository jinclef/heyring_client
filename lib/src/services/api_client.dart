import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as gx;
import '../routes/app_routes.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  final _storage = const FlutterSecureStorage();

  static const _rawBase = "http://10.0.2.2:8000";

  late final Dio dio = Dio(BaseOptions(
    baseUrl: _rawBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    // 4xx는 onError로 보내서 한곳에서 처리
    validateStatus: (status) => status != null && status < 400,
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
            await _storage.delete(key: 'auth_token');
            if (gx.Get.currentRoute != Routes.login) {
              gx.Get.offAllNamed(Routes.login);
            }
            // reject/throw 하지 않고, 조용히 마무리
            return handler.resolve(Response(
              requestOptions: response.requestOptions,
              statusCode: 401,
              data: null, // 호출부에서 안전하게 처리
            ));
          }
          handler.next(response);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
            if (gx.Get.currentRoute != Routes.login) {
              gx.Get.offAllNamed(Routes.login);
            }
          }
          handler.next(e);
        },
      ),
    );
}
