import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/api_client.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final StorageService storage = Get.find();
  final ApiClient _api = ApiClient.I;

  @override
  void onInit() {
    super.onInit();
    // isLoggedIn 변경 감지하여 자동 라우팅
    ever(isLoggedIn, (loggedIn) {
      if (loggedIn) {
        Get.offAllNamed(Routes.schedule);
      } else {
        if (Get.currentRoute != Routes.login) {
          Get.offAllNamed(Routes.login);
        }
      }
    });
  }

  // 로그인 요청
  Future<bool> login(String loginId) async {
    try {
      // 디바이스 정보 수집
      final deviceInfo = DeviceInfoPlugin();

      String platform;
      String deviceId;
      String userAgent;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'ANDROID';
        deviceId = androidInfo.id;
        userAgent = 'Android ${androidInfo.version.release} / ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'IOS';
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        userAgent = 'iOS ${iosInfo.systemVersion} / ${iosInfo.model}';
      } else {
        platform = 'WEB';
        deviceId = 'web-device';
        userAgent = 'Web';
      }

      final response = await _api.dio.post(
        '/auth/login',
        data: {
          'login_id': loginId,
          'platform': platform,
          'device_id': deviceId,
          'user_agent': userAgent,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // 토큰 저장
        await storage.setAuthToken(data['access_token'] as String);
        await storage.setRefreshToken(data['refresh_token'] as String);
        storage.userId = (data['user'] as Map)['id'] as String;

        isLoggedIn.value = true; // 이 시점에서 자동 라우팅 발생
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // 토큰 갱신
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _api.dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // 새 토큰 저장
        await storage.setAuthToken(data['access_token'] as String);
        await storage.setRefreshToken(data['refresh_token'] as String);

        return true;
      }
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  // 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    await storage.init();

    final token = await storage.getAuthToken();
    final userId = storage.userId;

    if (token != null && userId != null) {
      // 토큰 유효성 검증
      try {
        final response = await _api.dio.get('/auth/me');
        if (response.statusCode == 200) {
          isLoggedIn.value = true;
          return;
        }
      } catch (e) {
        // 401이면 refresh 시도
        if (await refreshToken()) {
          isLoggedIn.value = true;
          return;
        }
      }
    }

    // 실패시 로그아웃 처리
    await logout();
  }

  // 로그아웃
  Future<void> logout() async {
    await storage.clearAuth();
    isLoggedIn.value = false; // 이 시점에서 자동으로 로그인 페이지로 이동
  }

  // 디바이스 로그아웃 (백엔드 호출)
  Future<bool> logoutDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      String platform;
      String? deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'ANDROID';
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'IOS';
        deviceId = iosInfo.identifierForVendor;
      } else {
        platform = 'WEB';
        deviceId = 'web-device';
      }

      final response = await _api.dio.post(
        '/auth/logout/device',
        data: {
          'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      print('Logout device error: $e');
      return false;
    }
  }
}