// lib/src/controllers/time_settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_setting_model.dart';
import '../services/schedule_setting_api.dart';
import 'schedule_controller.dart';

class TimeSettingsController extends GetxController {
  final RxList<CallTime> callTimes = <CallTime>[].obs;
  final _api = ScheduleSettingApi();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFromServer();
  }

  // 서버에서 설정 불러오기
  Future<void> fetchFromServer() async {
    isLoading.value = true;
    try {
      final settings = await _api.fetchSettings();
      final list = <CallTime>[];
      for (final setting in settings) {
        list.addAll(CallTime.fromScheduleSetting(setting));
      }
      callTimes.assignAll(list);
    } catch (e) {
      print('Fetch settings error: $e');
    }
    isLoading.value = false;
  }

  /// 요일 중복 방지 (같은 요일, 같은 시간대는 불가)
  bool isWeekdayTaken(int weekday, {String? exceptKey}) {
    return callTimes.any((ct) =>
    ct.weekdays.contains(weekday) &&
        (exceptKey == null || ct.uniqueKey != exceptKey));
  }

  /// 스케줄 컨트롤러 새로고침 (알림도 자동 재예약됨)
  Future<void> _refreshSchedules() async {
    if (Get.isRegistered<ScheduleController>()) {
      await Get.find<ScheduleController>().refresh();
    }
  }

  // 추가 + 알림 동기화
  Future<void> add(TimeOfDay time, Set<int> weekdays) async {
    final filtered = weekdays.where((w) => !isWeekdayTaken(w)).toSet();
    if (filtered.isEmpty) {
      Get.snackbar('알림', '선택한 요일이 이미 사용 중입니다');
      return;
    }

    try {
      isLoading.value = true;

      final setting = await _api.createSetting(
        weekdays: filtered.map((w) => CallTime.weekdayMap[w]!).toList(),
        startTimes: [
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        ],
        duration: 60,
      );

      if (setting != null) {
        final newCallTimes = CallTime.fromScheduleSetting(setting);
        callTimes.addAll(newCallTimes);

        // 스케줄 새로고침 (알림도 자동 재예약됨)
        await _refreshSchedules();
      }
    } catch (e) {
      print('Add setting error: $e');
      Get.snackbar('오류', '설정 추가에 실패했습니다');
    } finally {
      isLoading.value = false;
    }
  }

  // 시간 또는 요일 수정 + 알림 재동기화
  Future<void> updateCallTime(String uniqueKey, {TimeOfDay? newTime, Set<int>? newWeekdays}) async {
    final ct = callTimes.firstWhereOrNull((e) => e.uniqueKey == uniqueKey);
    if (ct == null) return;

    try {
      isLoading.value = true;

      final updateData = <String, dynamic>{};

      if (newTime != null) {
        updateData['start_times'] = [
          '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}'
        ];
      }

      if (newWeekdays != null) {
        final filtered = newWeekdays.where((w) => !isWeekdayTaken(w, exceptKey: uniqueKey)).toSet();
        if (filtered.isEmpty) {
          Get.snackbar('알림', '선택한 요일이 이미 사용 중입니다');
          isLoading.value = false;
          return;
        }
        updateData['weekdays'] = filtered.map((w) => CallTime.weekdayMap[w]!).toList();
      }

      final setting = await _api.updateSetting(
        settingId: ct.settingId,
        weekdays: updateData['weekdays'],
        startTimes: updateData['start_times'],
      );

      if (setting != null) {
        // 기존 CallTime 제거하고 새로 추가
        callTimes.removeWhere((e) => e.settingId == ct.settingId);
        final newCallTimes = CallTime.fromScheduleSetting(setting);
        callTimes.addAll(newCallTimes);

        // 스케줄 새로고침 (알림도 자동 재예약됨)
        await _refreshSchedules();
      }
    } catch (e) {
      print('Update setting error: $e');
      Get.snackbar('오류', '수정에 실패했습니다');
    } finally {
      isLoading.value = false;
    }
  }

  // 삭제 + 관련 알림 취소
  Future<void> remove(String uniqueKey) async {
    final ct = callTimes.firstWhereOrNull((e) => e.uniqueKey == uniqueKey);
    if (ct == null) return;

    try {
      isLoading.value = true;

      final success = await _api.deleteSetting(ct.settingId);

      if (success) {
        callTimes.removeWhere((e) => e.settingId == ct.settingId);

        // 스케줄 새로고침 (알림도 자동 재예약됨)
        await _refreshSchedules();
      }
    } catch (e) {
      print('Delete setting error: $e');
      Get.snackbar('오류', '삭제에 실패했습니다');
    } finally {
      isLoading.value = false;
    }
  }
}