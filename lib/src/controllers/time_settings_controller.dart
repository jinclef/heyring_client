import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/call_time.dart';
import '../services/storage_service.dart';

class TimeSettingsController extends GetxController {
  final StorageService storage = Get.find();
  final RxList<CallTime> callTimes = <CallTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final raw = storage.readCallTimes();
    callTimes.assignAll(raw.map(CallTime.fromJson));
  }

  void _persist() {
    storage.writeCallTimes(callTimes.map((e) => e.toJson()).toList());
  }

  /// 요일 중복 방지: 하나의 요일은 한 CallTime에만 속할 수 있음
  bool isWeekdayTaken(int weekday, {String? exceptId}) {
    return callTimes.any((ct) =>
    ct.weekdays.contains(weekday) &&
        (exceptId == null || ct.id != exceptId));
  }

  void add(TimeOfDay time, Set<int> weekdays) {
    // 이미 점유된 요일 제외
    final filtered = weekdays.where((w) => !isWeekdayTaken(w)).toSet();
    if (filtered.isEmpty) return;
    callTimes.add(CallTime(id: const Uuid().v4(), time: time, weekdays: filtered));
    _persist();
  }

  void updateTime(String id, TimeOfDay newTime) {
    final idx = callTimes.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    callTimes[idx] = callTimes[idx].copyWith(time: newTime);
    _persist();
  }

  void updateWeekdays(String id, Set<int> newWeekdays) {
    final idx = callTimes.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    // 다른 설정이 이미 점유한 요일은 제외
    final filtered = newWeekdays.where((w) => !isWeekdayTaken(w, exceptId: id)).toSet();
    callTimes[idx] = callTimes[idx].copyWith(weekdays: filtered);
    _persist();
  }

  void remove(String id) {
    callTimes.removeWhere((e) => e.id == id);
    _persist();
  }
}
