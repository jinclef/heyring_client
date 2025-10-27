// lib/src/services/auth_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';

enum AppPlatform { android, ios, web }

// 서버 스키마(응답)와 맞춘 간단 DTO
class TokenRes {
  final String accessToken;
  final String refreshToken;
  final int accessExpiresIn;   // seconds
  final int refreshExpiresIn;  // seconds
  final String jti;

  TokenRes({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
    required this.jti,
  });

  factory TokenRes.fromJson(Map<String, dynamic> json) => TokenRes(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresIn: json['access_expires_in'] as int,
    refreshExpiresIn: json['refresh_expires_in'] as int,
    jti: json['jti'] as String,
  );
}

class AuthService {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kAccessExpAt = 'access_exp_at';   // ms epoch
  static const _kRefreshExpAt = 'refresh_exp_at'; // ms epoch
  static const _kDeviceId = 'device_id';          // 앱에서 생성/보관

  final _storage = const FlutterSecureStorage();
  final Dio _dio = ApiClient().dio;

  /// 앱 시작 시 1회 호출 권장
  Future<void> init() async {
    await ApiClient().init();
  }

  /// 서버 LoginReq 스키마에 맞춰 요청
  /// - login_id: 이메일/아이디 매핑
  /// - platform: 'android' | 'ios' | 'web'
  /// - device_id: 기기 식별자(앱에서 생성/보관)
  /// - device_token, app_version, user_agent: 선택
  Future<bool> login({
    required String loginId,
    required String password,
    required AppPlatform platform,
    String? deviceId,
    String? deviceToken,
    String? appVersion,
    String? userAgent,
  }) async {
    final savedDeviceId =
        deviceId ?? await _storage.read(key: _kDeviceId) ?? _genDeviceId();
    await _storage.write(key: _kDeviceId, value: savedDeviceId);

    final payload = {
      'login_id': loginId,
      'password': password, // FastAPI에서 검증 안쓰면 무시됨
      'platform': _platStr(platform), // 서버 PlatformEnum과 일치해야 함
      'device_id': savedDeviceId,
      'device_token': deviceToken,
      'app_version': appVersion,
      'user_agent': userAgent ?? _defaultUA(),
    };

    final resp = await _dio.post('/auth/login', data: payload);
    final body = TokenRes.fromJson(resp.data as Map<String, dynamic>);
    await _saveTokens(body);
    return true;
  }

  Future<void> logoutDevice({required AppPlatform platform}) async {
    try {
      final deviceId = await _storage.read(key: _kDeviceId);
      await _dio.post('/auth/logout/device', data: {
        'platform': _platStr(platform),
        'device_id': deviceId, // null도 허용: 플랫폼 전체 로그아웃
      });
    } finally {
      // 서버 세션 무효화와 별개로 로컬 토큰 제거
      await _clearTokens();
    }
  }

  /// 간단 자동로그인 판단: access 유효/또는 refresh로 갱신 가능
  Future<bool> hasValidSession() async {
    final access = await _storage.read(key: _kAccess);
    final accessExpAtStr = await _storage.read(key: _kAccessExpAt);
    final refresh = await _storage.read(key: _kRefresh);

    final now = DateTime.now().millisecondsSinceEpoch;

    if (access != null && accessExpAtStr != null) {
      final accessExpAt = int.tryParse(accessExpAtStr) ?? 0;
      if (now < accessExpAt - 3000) {
        // 3초 여유
        return true;
      }
    }
    // access 만료: refresh 시도
    if (refresh != null && refresh.isNotEmpty) {
      try {
        final resp = await _dio.post('/auth/refresh', data: {
          'refresh_token': refresh,
        });
        final body = TokenRes.fromJson(resp.data as Map<String, dynamic>);
        await _saveTokens(body);
        return true;
      } catch (_) {
        // 실패 시 false
      }
    }
    return false;
  }

  Future<void> _saveTokens(TokenRes t) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final accessExpAt = nowMs + t.accessExpiresIn * 1000;
    final refreshExpAt = nowMs + t.refreshExpiresIn * 1000;

    await _storage.write(key: _kAccess, value: t.accessToken);
    await _storage.write(key: _kRefresh, value: t.refreshToken);
    await _storage.write(key: _kAccessExpAt, value: accessExpAt.toString());
    await _storage.write(key: _kRefreshExpAt, value: refreshExpAt.toString());
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kAccessExpAt);
    await _storage.delete(key: _kRefreshExpAt);
  }

  String _platStr(AppPlatform p) {
    switch (p) {
      case AppPlatform.android:
        return 'android';
      case AppPlatform.ios:
        return 'ios';
      case AppPlatform.web:
        return 'web';
    }
  }

  String _defaultUA() {
    final os = Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
        ? 'iOS'
        : Platform.operatingSystem;
    return 'FlutterApp/1.0 ($os)';
  }

  String _genDeviceId() {
    // 아주 단순한 랜덤 ID(실서비스는 device_info_plus 등으로 더 안정적으로 생성 권장)
    return 'dev-${DateTime.now().microsecondsSinceEpoch}-${_rand4()}';
  }

  String _rand4() {
    final r = (DateTime.now().microsecondsSinceEpoch % 10000).toString();
    return r.padLeft(4, '0');
  }
}
