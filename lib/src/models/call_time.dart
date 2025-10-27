import 'package:flutter/material.dart';

/// 하루 중 시:분, 그리고 반복 요일 세트
class CallTime {
  final String id;
  final TimeOfDay time;        // 11:30
  final Set<int> weekdays;     // 1~7 (월=1 ... 일=7)

  CallTime({
    required this.id,
    required this.time,
    required this.weekdays,
  });

  CallTime copyWith({TimeOfDay? time, Set<int>? weekdays}) {
    return CallTime(id: id, time: time ?? this.time, weekdays: weekdays ?? this.weekdays);
  }

  factory CallTime.fromJson(Map<String, dynamic> json) {
    return CallTime(
      id: json['id'] as String,
      time: TimeOfDay(hour: json['h'] as int, minute: json['m'] as int),
      weekdays: (json['w'] as List).map((e) => e as int).toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'h': time.hour,
    'm': time.minute,
    'w': weekdays.toList()..sort(),
  };
}
