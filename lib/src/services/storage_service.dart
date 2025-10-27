import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late GetStorage _box;

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
}
