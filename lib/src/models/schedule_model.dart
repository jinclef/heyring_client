// lib/src/models/schedule_model.dart
import 'package:flutter/material.dart';

enum ScheduleStatus {
  scheduled('SCHEDULED'),
  completed('COMPLETED'),
  skipped('SKIPPED'),
  cancelled('CANCELLED');

  final String value;
  const ScheduleStatus(this.value);

  static ScheduleStatus fromString(String s) {
    return ScheduleStatus.values.firstWhere((e) => e.value == s);
  }
}

class Schedule {
  final int id;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final TimeOfDay endTime;
  final ScheduleStatus status;
  final int? scheduleSettingId;

  Schedule({
    required this.id,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.endTime,
    required this.status,
    this.scheduleSettingId,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final dateStr = json['scheduled_date'] as String; // "2025-01-15"
    final timeStr = json['scheduled_time'] as String; // "09:00:00"
    final endTimeStr = json['end_time'] as String; // "10:00:00"

    final date = DateTime.parse(dateStr);
    final timeParts = timeStr.split(':');
    final endTimeParts = endTimeStr.split(':');

    return Schedule(
      id: json['id'] as int,
      scheduledDate: date,
      scheduledTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      status: ScheduleStatus.fromString(json['status'] as String),
      scheduleSettingId: json['schedule_setting_id'] as int?,
    );
  }

  bool get isCompleted => status == ScheduleStatus.completed;
  bool get isSkipped => status == ScheduleStatus.skipped;
  bool get isScheduled => status == ScheduleStatus.scheduled;
}