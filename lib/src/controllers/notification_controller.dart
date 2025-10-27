// lib/src/controllers/notification_controller.dart
import 'package:get/get.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final _svc = NotificationService();

  @override
  void onInit() {
    super.onInit();
    _svc.init();
  }

  Future<void> showNow(String title, String body) => _svc.showNow(title: title, body: body);

  Future<void> scheduleOnce({
    required int id,
    required DateTime localTime,
    required String title,
    required String body,
  }) => _svc.scheduleOnce(id: id, localTime: localTime, title: title, body: body);
}
