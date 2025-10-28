// lib/src/controllers/schedule_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/schedule_api.dart';
import '../models/schedule_model.dart';

class DayItem {
  final DateTime date;
  final TimeOfDay? callAt;
  final bool isCompleted;
  final bool isSkipped;
  final int? scheduleId;

  DayItem({
    required this.date,
    this.callAt,
    required this.isCompleted,
    required this.isSkipped,
    this.scheduleId,
  });
}

class ScheduleController extends GetxController {
  final schedules = <Schedule>[].obs;
  final isLoading = false.obs;
  final scrollController = ScrollController();

  final _api = ScheduleApi();

  // 이번주 월요일 계산
  DateTime get thisWeekMonday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1(월) ~ 7(일)
    return today.subtract(Duration(days: weekday - 1));
  }

  // 다음주 일요일 계산
  DateTime get nextWeekSunday {
    return thisWeekMonday.add(const Duration(days: 13));
  }

  // 오늘의 인덱스 (스크롤 위치용)
  int get todayIndex {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = thisWeekMonday;
    return today.difference(start).inDays;
  }

  // 현재 표시 중인 날짜 범위의 월/년 정보 (표시용)
  String get displayMonthYear {
    schedules.length; // reactive하게 만들기

    final start = thisWeekMonday;
    final end = nextWeekSunday;

    if (start.month == end.month) {
      return '${start.year}년 ${start.month}월';
    }
    return '${start.year}년 ${start.month}월 - ${end.month}월';
  }

  List<DayItem> get days {
    final start = thisWeekMonday;
    final end = nextWeekSunday;

    final items = <DayItem>[];
    for (var d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      final daySchedules = schedules.where((s) =>
      s.scheduledDate.year == d.year &&
          s.scheduledDate.month == d.month &&
          s.scheduledDate.day == d.day
      ).toList();

      if (daySchedules.isNotEmpty) {
        final firstSchedule = daySchedules.first;
        items.add(DayItem(
          date: d,
          callAt: firstSchedule.scheduledTime,
          isCompleted: firstSchedule.isCompleted,
          isSkipped: firstSchedule.isSkipped,
          scheduleId: firstSchedule.id,
        ));
      } else {
        items.add(DayItem(
          date: d,
          callAt: null,
          isCompleted: false,
          isSkipped: false,
          scheduleId: null,
        ));
      }
    }

    return items;
  }

  // 오늘로 스크롤 (항상 실행)
  void scrollToToday() {
    if (!scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), scrollToToday);
      return;
    }

    final index = todayIndex;
    if (index >= 0 && index < days.length) {
      final itemHeight = 70.0; // schedule_item_tile 높이.
      scrollController.jumpTo(index * itemHeight);
    }
  }

  Future<void> fetchTwoWeeks() async {
    try {
      isLoading.value = true;

      final start = thisWeekMonday;
      final end = nextWeekSunday;

      final items = await _api.fetchSchedules(
        startDate: start,
        endDate: end,
      );

      schedules.assignAll(items);

      // 데이터 로드 후 항상 오늘로 스크롤
      Future.delayed(const Duration(milliseconds: 100), scrollToToday);
    } catch (e) {
      print('fetchTwoWeeks error: $e');
      // 401 에러는 인터셉터에서 처리되어 자동 로그아웃됨
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateScheduleTime(int scheduleId, TimeOfDay newTime) async {
    try {
      final schedule = await _api.updateSchedule(
        scheduleId: scheduleId,
        startTime: newTime,
      );

      if (schedule != null) {
        await fetchTwoWeeks();
        return true;
      }
      return false;
    } catch (e) {
      print('Update schedule time error: $e');
      return false;
    }
  }

// 스케줄 건너뛰기
  Future<bool> skipSchedule(int scheduleId) async {
    try {
      final success = await _api.skipSchedule(scheduleId);
      if (success) {
        await fetchTwoWeeks();
      }
      return success;
    } catch (e) {
      print('Skip schedule error: $e');
      return false;
    }
  }

// 스케줄 복원
  Future<bool> restoreSchedule(int scheduleId) async {
    try {
      final success = await _api.restoreSchedule(scheduleId);
      if (success) {
        await fetchTwoWeeks();
      }
      return success;
    } catch (e) {
      print('Restore schedule error: $e');
      return false;
    }
  }

// 스케줄 삭제
  Future<bool> deleteSchedule(int scheduleId) async {
    try {
      final success = await _api.deleteSchedule(scheduleId);
      if (success) {
        await fetchTwoWeeks();
      }
      return success;
    } catch (e) {
      print('Delete schedule error: $e');
      return false;
    }
  }

  // 새로고침 - 항상 오늘로
  Future<void> refresh() async {
    await fetchTwoWeeks();
  }

  @override
  void onInit() {
    super.onInit();
    // fetchTwoWeeks();
  }

  @override
  void onReady() {
    super.onReady();
    if (schedules.isNotEmpty) {
      scrollToToday();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}