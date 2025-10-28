import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// 백그라운드 알림 처리 (최상위 함수 또는 static 함수여야 함)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification tapped: ${notificationResponse.id}');
}

class FlutterLocalNotification {
  FlutterLocalNotification._();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification clicked: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void requestNotificationPermission() {
    // iOS
    flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ (POST_NOTIFICATIONS)
    flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // (선택) 정확 알람 권한 요청 - 설정 화면으로 유도됨 (API 제공됨)
    flutterLocalNotificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }


  static Future<void> showNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        'heyring_schedule',
        '전화 일정 알림',
        channelDescription: '예약된 전화 시간 알림',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(badgeNumber: 1),
    );

    await flutterLocalNotificationPlugin.show(
      0,
      '통화',
      '통화',
      notificationDetails,
    );
  }

  /// 스케줄 알림 예약 (스케줄 ID를 알림 ID로 사용)
  static Future<void> scheduleNotification({
    required int scheduleId,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();

    // 과거 시간이면 예약하지 않음
    if (dateTime.isBefore(now)) {
      print('Skip past time: ID=$scheduleId');
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

    // TZ 기준으로도 과거면 스킵
    final tzNow = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(tzNow)) {
      print('Skip past TZ time: ID=$scheduleId');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'heyring_schedule',
        '전화 일정 알림',
        channelDescription: '예약된 전화 시간 알림',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        // 앱이 켜져 있어도 알림 표시
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      print('[NOTI] now=${tz.TZDateTime.now(tz.local)}  schedule=$scheduledDate  id=$scheduleId');
      await flutterLocalNotificationPlugin.zonedSchedule(
        scheduleId,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final timeUntil = scheduledDate.difference(tzNow);
    } catch (e) {
      print('Failed to schedule ID=$scheduleId: $e');
    }
  }

  /// 특정 알림 취소
  static Future<void> cancelNotification(int scheduleId) async {
    try {
      await flutterLocalNotificationPlugin.cancel(scheduleId);
      print('Cancelled ID=$scheduleId');
    } catch (e) {
      print('Cancel failed: $e');
    }
  }

  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationPlugin.cancelAll();
      print('🗑️  All notifications cancelled');
    } catch (e) {
      print('Cancel all failed: $e');
    }
  }

  /// 예약된 알림 목록 확인
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await flutterLocalNotificationPlugin.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (final n in pending) {
      print('   - ID: ${n.id}, Title: ${n.title}');
    }
    return pending;
  }

  /// 여러 스케줄에 대한 알림 일괄 예약
  static Future<void> scheduleMultipleNotifications(
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
  static Future<void> cancelMultipleNotifications(List<int> scheduleIds) async {
    for (final id in scheduleIds) {
      await cancelNotification(id);
    }
  }

  /// 테스트용: 1분 후 알림
  static Future<void> scheduleTestNotification() async {
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    await scheduleNotification(
      scheduleId: 99999,
      dateTime: testTime,
      title: '🧪 테스트 통화',
      body: '1분 후 테스트 알림',
    );
    print('🧪 Test notification scheduled for 1 minute');
  }
}