// lib/src/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._internal();
  factory NotificationService() => _i;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _canScheduleExactAlarms = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const init = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 클릭 시 처리 (필요시 구현)
        print('Notification clicked: ${response.payload}');
      },
    );

    // iOS 권한 요청
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Android 권한 요청
    if (Platform.isAndroid) {
      // Android 13+ 알림 권한
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Android 12+ 정확한 알람 권한 확인
      await _checkExactAlarmPermission();
    }

    _initialized = true;
  }

  /// Android 12+ 정확한 알람 권한 확인
  Future<void> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Android 12+ 에서 정확한 알람 권한 확인
        final canSchedule = await androidImpl.canScheduleExactNotifications();
        _canScheduleExactAlarms = canSchedule ?? false;

        if (!_canScheduleExactAlarms) {
          print('Exact alarms not permitted. Using inexact scheduling.');
          print('Guide user to: Settings > Apps > Heyring > Alarms & reminders');
        } else {
          print('Exact alarms permission granted');
        }
      }
    } catch (e) {
      print('Error checking exact alarm permission: $e');
      _canScheduleExactAlarms = false;
    }
  }

  Future<void> showNow({required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'heyring_default',
        '일반 알림',
        channelDescription: '일반 알림',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF,
      title,
      body,
      details,
    );
  }

  /// 스케줄 알림 예약 (스케줄 ID를 알림 ID로 사용)
  Future<void> scheduleNotification({
    required int scheduleId,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    // 과거 시간이면 예약하지 않음
    if (dateTime.isBefore(DateTime.now())) {
      print('Cannot schedule notification for past time: $dateTime');
      return;
    }

    final scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      0,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'heyring_schedule',
        '전화 일정 알림',
        channelDescription: '예약된 전화 시간 알림',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      // Android: 정확한 알람 권한에 따라 다른 스케줄 모드 사용
      AndroidScheduleMode scheduleMode;
      if (Platform.isAndroid) {
        scheduleMode = _canScheduleExactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

        if (!_canScheduleExactAlarms) {
          print('Using inexact scheduling for notification ID=$scheduleId');
        }
      } else {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      await _plugin.zonedSchedule(
        scheduleId,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('Notification scheduled: ID=$scheduleId at $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int scheduleId) async {
    try {
      await _plugin.cancel(scheduleId);
      print('Notification cancelled: ID=$scheduleId');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// 예약된 알림 목록 확인 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// 정확한 알람 권한이 있는지 확인
  bool get hasExactAlarmPermission => _canScheduleExactAlarms;

  /// 여러 스케줄에 대한 알림 일괄 예약
  Future<void> scheduleMultipleNotifications(
      List<Map<String, dynamic>> schedules,
      ) async {
    for (final schedule in schedules) {
      await scheduleNotification(
        scheduleId: schedule['id'] as int,
        dateTime: schedule['dateTime'] as DateTime,
        title: schedule['title'] as String? ?? '통화',
        body: schedule['body'] as String? ?? '통화',
      );
    }
  }

  /// 여러 알림 취소
  Future<void> cancelMultipleNotifications(List<int> scheduleIds) async {
    for (final id in scheduleIds) {
      await cancelNotification(id);
    }
  }
}