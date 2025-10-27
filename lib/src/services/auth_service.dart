import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();

  /// 실제 기기 정보를 기반으로 로그인 요청
  Future<bool> loginWithId(String rawId) async {
    final id = rawId.trim();
    if (id.isEmpty) return false;

    // === 기기 정보 수집 ===
    String platform = Platform.isIOS
        ? 'IOS'
        : Platform.isAndroid
        ? 'ANDROID'
        : 'WEB';

    String deviceId = 'unknown';
    String deviceModel = '';
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        deviceId = info.id;
        deviceModel = info.model;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? 'unknown';
        deviceModel = info.utsname.machine ?? '';
      } else {
        deviceId = Platform.localHostname;
        deviceModel = 'WebClient';
      }
    } catch (_) {}

    // final package = await PackageInfo.fromPlatform();

    // === 실제 body ===
    final body = {
      'login_id': id,
      'platform': platform, // 서버 Enum과 일치 (IOS/ANDROID/WEB)
      'device_id': deviceId,
      'device_token': null, // TODO: FCM token 연동 시 여기에 주입
      // 'app_version': package.version,
      // 'user_agent': '$platform/$deviceModel (${package.packageName})',
    };

    try {
      final res = await ApiClient.I.dio.post(
        '/auth/login',
        data: body,
        options: dio.Options(contentType: 'application/json'),
      );

      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        // 디버그 로그 원하면 아래 주석 해제
        // print('login failed: $code ${res.data}');
        return false;
      }

      final token = (res.data?['access_token'] as String?) ?? '';
      if (token.isEmpty) return false;

      await _storage.write(key: _keyToken, value: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async => _storage.delete(key: _keyToken);

  Future<bool> hasToken() async {
    final t = await _storage.read(key: _keyToken);
    return t != null && t.isNotEmpty;
  }
}
