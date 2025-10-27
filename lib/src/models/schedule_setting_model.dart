// lib/src/models/schedule_setting_model.dart
import 'package:flutter/material.dart';

class ScheduleSetting {
  final int id;
  final List<String> weekdays; // ["MON", "WED", "FRI"]
  final List<String> startTimes; // ["09:00", "14:00"]
  final int duration;
  final String weekdaysKey;

  ScheduleSetting({
    required this.id,
    required this.weekdays,
    required this.startTimes,
    required this.duration,
    required this.weekdaysKey,
  });

  factory ScheduleSetting.fromJson(Map<String, dynamic> json) {
    return ScheduleSetting(
      id: json['id'] as int,
      weekdays: List<String>.from(json['weekdays'] as List),
      startTimes: List<String>.from(json['start_times'] as List),
      duration: json['duration'] as int,
      weekdaysKey: json['weekdays_key'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekdays': weekdays,
    'start_times': startTimes,
    'duration': duration,
    'weekdays_key': weekdaysKey,
  };
}

// UI 표시용 모델
class CallTime {
  final int settingId; // ScheduleSetting ID
  final TimeOfDay time;
  final Set<int> weekdays; // 1~7 (월=1 ... 일=7)
  final int duration;

  CallTime({
    required this.settingId,
    required this.time,
    required this.weekdays,
    this.duration = 60,
  });

  static const Map<int, String> weekdayMap = {
    1: 'MON', 2: 'TUE', 3: 'WED', 4: 'THU',
    5: 'FRI', 6: 'SAT', 7: 'SUN',
  };

  static const Map<String, int> reverseWeekdayMap = {
    'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4,
    'FRI': 5, 'SAT': 6, 'SUN': 7,
  };

  List<String> get weekdaysForApi {
    return weekdays.map((w) => weekdayMap[w]!).toList()..sort();
  }

  String get startTimeForApi {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ScheduleSetting 하나가 여러 시간을 가질 수 있으므로,
  // ScheduleSetting 하나당 여러 CallTime 생성
  static List<CallTime> fromScheduleSetting(ScheduleSetting setting) {
    final weekdays = setting.weekdays
        .map((w) => reverseWeekdayMap[w]!)
        .toSet();

    return setting.startTimes.map((timeStr) {
      final parts = timeStr.split(':');
      final time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      return CallTime(
        settingId: setting.id,
        time: time,
        weekdays: weekdays,
        duration: setting.duration,
      );
    }).toList();
  }

  // 고유 키 (UI에서 구분용)
  String get uniqueKey => '$settingId-${time.hour}-${time.minute}';

  CallTime copyWith({TimeOfDay? time, Set<int>? weekdays}) {
    return CallTime(
      settingId: settingId,
      time: time ?? this.time,
      weekdays: weekdays ?? this.weekdays,
      duration: duration,
    );
  }
}