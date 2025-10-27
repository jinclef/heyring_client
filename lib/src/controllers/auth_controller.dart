import 'package:get/get.dart';
import '../services/storage_service.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final StorageService storage = Get.find();

  Future<void> tryAutoLogin() async {
    await Get.find<StorageService>().init();
    isLoggedIn.value = storage.userId != null;
  }

  Future<bool> loginWithId(String id) async {
    if (id.trim().isEmpty) return false;
    // (실서비스라면 백엔드 검증 호출)
    storage.userId = id.trim();
    isLoggedIn.value = true;
    return true;
  }

  void logout() {
    storage.userId = null;
    isLoggedIn.value = false;
  }
}
