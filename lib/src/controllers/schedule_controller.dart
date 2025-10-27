// lib/src/controllers/schedule_controller.dart
import 'package:get/get.dart';
import '../services/schedule_api.dart';
import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';

class Schedule {
  final DateTime date;
  final int? callHour;
  final int? callMinute;
  final bool isCompleted;

  Schedule({
    required this.date,
    required this.isCompleted,
    this.callHour,
    this.callMinute,
  });

  factory Schedule.fromDto(ScheduleDto d) => Schedule(
        date: d.date,
        isCompleted: d.isCompleted,
        callHour: d.callHour,
        callMinute: d.callMinute,
      );
}

class DayItem {
  final DateTime date;
  final TimeOfDay? callAt;
  final bool isCompleted;
  DayItem({required this.date, required this.callAt, required this.isCompleted});
}

class ScheduleController extends GetxController {
  final currentMonth = DateTime.now().obs;
  final schedules = <Schedule>[].obs;

  final _api = ScheduleApi();

  String monthTitleKr(DateTime d) => '${d.year}년 ${d.month}월';

  List<DayItem> get days => schedules.map((s) {
    final callAt = (s.callHour != null && s.callMinute != null)
        ? TimeOfDay(hour: s.callHour!, minute: s.callMinute!)
        : null;
    return DayItem(date: s.date, callAt: callAt, isCompleted: s.isCompleted);
  }).toList();

  Future<void> fetchMonth(DateTime month) async {
    final items = await _api.fetchMonth(year: month.year, month: month.month);
    final list = items.map((e) => Schedule.fromDto(e)).toList();
    schedules.assignAll(list);

    // 예약 알림 등록
    final notif = Get.find<NotificationController>();
    for (final s in schedules) {
      if (s.callHour != null && s.callMinute != null) {
        final when = DateTime(s.date.year, s.date.month, s.date.day, s.callHour!, s.callMinute!);
        if (when.isAfter(DateTime.now())) {
          final id = when.millisecondsSinceEpoch % 0x7FFFFFFF;
          await notif.scheduleOnce(
            id: id,
            localTime: when,
            title: '통화 알림',
            body: '${s.date.month}월 ${s.date.day}일 '
                  '${s.callHour!.toString().padLeft(2, '0')}:${s.callMinute!.toString().padLeft(2, '0')} 통화 예정',
          );
        }
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchMonth(currentMonth.value);
  }

  void goPrevMonth() {
    final d = currentMonth.value;
    currentMonth.value = DateTime(d.year, d.month - 1, 1);
    fetchMonth(currentMonth.value);
  }

  void goNextMonth() {
    final d = currentMonth.value;
    currentMonth.value = DateTime(d.year, d.month + 1, 1);
    fetchMonth(currentMonth.value);
  }
}
