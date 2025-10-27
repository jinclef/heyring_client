import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService extends GetxService {
  late GetStorage _box;
  final _secureStorage = const FlutterSecureStorage();

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // 로그인 id
  String? get userId => _box.read('userId');
  set userId(String? v) => v == null ? _box.remove('userId') : _box.write('userId', v);

  // 시간설정 JSON
  List<Map<String, dynamic>> readCallTimes() {
    final list = (_box.read('callTimes') ?? []) as List;
    return list.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void writeCallTimes(List<Map<String, dynamic>> data) {
    _box.write('callTimes', data);
  }

  // Auth Token (secure storage)
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> setAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Refresh Token (secure storage)
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  // 모든 인증 정보 삭제
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    userId = null;
  }
}