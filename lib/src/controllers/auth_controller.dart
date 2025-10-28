// lib/src/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/api_client.dart';
import '../routes/app_routes.dart';
import 'schedule_controller.dart';
import 'time_settings_controller.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final StorageService storage = Get.find();
  final ApiClient _api = ApiClient.I;

  @override
  void onInit() {
    super.onInit();

    ever(isLoggedIn, (loggedIn) {
      if (loggedIn) {
        _initializeControllers();
        Get.offAllNamed(Routes.schedule);
      } else {
        _clearControllers();
        if (Get.currentRoute != Routes.login) {
          Get.offAllNamed(Routes.login);
        }
      }
    });
  }

  void _initializeControllers() {
    if (Get.isRegistered<ScheduleController>()) {
      final scheduleController = Get.find<ScheduleController>();
      scheduleController.fetchTwoWeeks();
    }

    if (Get.isRegistered<TimeSettingsController>()) {
      final timeSettingsController = Get.find<TimeSettingsController>();
      timeSettingsController.fetchFromServer();
    }
  }

  void _clearControllers() {
    if (Get.isRegistered<ScheduleController>()) {
      final scheduleController = Get.find<ScheduleController>();
      scheduleController.schedules.clear();
    }

    if (Get.isRegistered<TimeSettingsController>()) {
      final timeSettingsController = Get.find<TimeSettingsController>();
      timeSettingsController.callTimes.clear();
    }
  }

  Future<bool> login(String loginId) async {
    try {
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

        await storage.setAuthToken(data['access_token'] as String);
        await storage.setRefreshToken(data['refresh_token'] as String);
        storage.userId = (data['user'] as Map)['id'] as String;

        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

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

  Future<void> tryAutoLogin() async {
    await storage.init();

    final token = await storage.getAuthToken();
    final userId = storage.userId;

    if (token != null && userId != null) {
      try {
        final response = await _api.dio.get('/auth/me');
        if (response.statusCode == 200) {
          isLoggedIn.value = true;
          return;
        }
      } catch (e) {
        if (await refreshToken()) {
          isLoggedIn.value = true;
          return;
        }
      }
    }

    await logout();
  }

  Future<void> logout() async {
    await storage.clearAuth();
    isLoggedIn.value = false;
  }

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

      try {
        await _api.dio.post(
          '/auth/logout/device',
          data: {
            'platform': platform,
            if (deviceId != null) 'device_id': deviceId,
          },
        );
      } catch (e) {
        // API 에러 무시
      }

      // API 성공/실패 관계없이 로그아웃
      await logout();
      return true;
    } catch (e) {
      print('Logout device error: $e');
      await logout();
      return false;
    }
  }
}