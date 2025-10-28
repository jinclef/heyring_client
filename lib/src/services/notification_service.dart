// lib/src/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// 백그라운드 알림 처리 (최상위 함수 또는 static 함수여야 함)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification tapped: ${notificationResponse.id}');
}

class NotificationService {
  static final NotificationService _i = NotificationService._internal();
  factory NotificationService() => _i;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _canScheduleExactAlarms = false;

  Future<void> init() async {
    if (_initialized) return;

    print('Initializing NotificationService...');

    // timezone 설정
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,  // 나중에 요청
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification clicked: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    print('Plugin initialized');

    // 권한 요청 (초기화 후)
    await _requestPermissions();

    _initialized = true;
    print('NotificationService initialized');
  }

  /// Timezone 설정
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print(' Timezone: $timeZoneName');
    } catch (e) {
      print(' Timezone fallback to Asia/Seoul');
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
  }

  /// 권한 요청 (초기화 후)
  Future<void> _requestPermissions() async {
    // iOS 권한 요청
    if (Platform.isIOS) {
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print(' iOS permission: $granted');
      }
    }

    // Android 권한 요청 및 채널 생성
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Android 13+ 알림 권한
        final granted = await androidImpl.requestNotificationsPermission();
        print(' Android notification permission: $granted');

        // Android 12+ 정확한 알람 권한 확인
        await _checkExactAlarmPermission();

        // 알림 채널 생성
        await _createNotificationChannels(androidImpl);
      }
    }
  }
  Future<void> _createNotificationChannels(AndroidFlutterLocalNotificationsPlugin androidImpl) async {
    // 스케줄 알림 채널
    const scheduleChannel = AndroidNotificationChannel(
      'heyring_schedule',
      '전화 일정 알림',
      description: '예약된 전화 시간 알림',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await androidImpl.createNotificationChannel(scheduleChannel);
    print(' Schedule channel created');

    // 일반 알림 채널
    const defaultChannel = AndroidNotificationChannel(
      'heyring_default',
      '일반 알림',
      description: '일반 알림',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImpl.createNotificationChannel(defaultChannel);
    print(' Default channel created');
  }

  /// Android 12+ 정확한 알람 권한 확인
  Future<void> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final canSchedule = await androidImpl.canScheduleExactNotifications();
        _canScheduleExactAlarms = canSchedule ?? false;

        if (!_canScheduleExactAlarms) {
          print(' Exact alarms NOT permitted (±15min delay)');
          print(' Enable: Settings > Apps > Heyring > Alarms & reminders');
          print(' Or call: requestExactAlarmPermission()');
        } else {
          print(' Exact alarms permitted');
        }
      }
    } catch (e) {
      print(' Error checking exact alarm: $e');
      _canScheduleExactAlarms = false;
    }
  }

  /// 정확한 알람 권한 설정 페이지로 이동 (Android 12+)
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // 권한이 이미 있는지 확인
        final canSchedule = await androidImpl.canScheduleExactNotifications();

        if (canSchedule == true) {
          print('Exact alarm permission already granted');
          _canScheduleExactAlarms = true;
          return;
        }

        // 설정 페이지로 이동
        final result = await androidImpl.requestExactAlarmsPermission();
        print('Opened exact alarm settings: $result');

        // 권한 상태 재확인
        await _checkExactAlarmPermission();
      }
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
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
    print('Immediate notification shown');
  }

  /// 스케줄 알림 예약 (스케줄 ID를 알림 ID로 사용)
  Future<void> scheduleNotification({
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
      AndroidScheduleMode scheduleMode;
      String modeText;

      if (Platform.isAndroid) {
        if (_canScheduleExactAlarms) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
          modeText = 'EXACT';
        } else {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          modeText = 'INEXACT';
        }
      } else {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        modeText = 'EXACT';
      }

      await _plugin.zonedSchedule(
        scheduleId,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
      );

      final timeUntil = scheduledDate.difference(tzNow);
      print('Scheduled ID=$scheduleId [$modeText] in ${timeUntil.inMinutes}min');
    } catch (e) {
      print('Failed to schedule ID=$scheduleId: $e');
    }
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int scheduleId) async {
    try {
      await _plugin.cancel(scheduleId);
      print('Cancelled ID=$scheduleId');
    } catch (e) {
      print('Cancel failed: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      print('🗑️  All notifications cancelled');
    } catch (e) {
      print('Cancel all failed: $e');
    }
  }

  /// 예약된 알림 목록 확인
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (final n in pending) {
      print('   - ID: ${n.id}, Title: ${n.title}');
    }
    return pending;
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

  /// 테스트용: 1분 후 알림
  Future<void> scheduleTestNotification() async {
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