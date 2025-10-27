// lib/src/models/schedule_model.dart
import 'package:flutter/material.dart';

class Schedule {
  final int id;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final TimeOfDay endTime;
  final String status;
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
    // scheduled_time 파싱 (HH:MM:SS 형식)
    final timeStr = json['scheduled_time'] as String;
    final timeParts = timeStr.split(':');
    final scheduledTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    // end_time 파싱 (HH:MM:SS 형식)
    final endTimeStr = json['end_time'] as String;
    final endTimeParts = endTimeStr.split(':');
    final endTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );

    return Schedule(
      id: json['id'] as int,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: scheduledTime,
      endTime: endTime,
      status: json['status'] as String,
      scheduleSettingId: json['schedule_setting_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
    'scheduled_time':
    '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
    'end_time':
    '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
    'status': status,
    if (scheduleSettingId != null) 'schedule_setting_id': scheduleSettingId,
  };

  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isScheduled => status == 'scheduled';
}