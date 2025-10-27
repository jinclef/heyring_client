import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/time_settings_controller.dart';
import '../services/storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Get.put(StorageService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(TimeSettingsController(), permanent: true);
    Get.put(ScheduleController(), permanent: true);
  }
}
