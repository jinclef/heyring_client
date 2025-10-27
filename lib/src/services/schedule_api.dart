// lib/src/services/schedule_api.dart
import 'package:dio/dio.dart';
import 'api_client.dart';

class ScheduleDto {
  final DateTime date;
  final int? callHour;
  final int? callMinute;
  final bool isCompleted;
  final int? durationMinutes;

  ScheduleDto({
    required this.date,
    required this.isCompleted,
    this.callHour,
    this.callMinute,
    this.durationMinutes,
  });

  factory ScheduleDto.fromJson(Map<String, dynamic> j) {
    DateTime d;
    final raw = j['date'];
    if (raw is String) {
      d = DateTime.parse(raw);
    } else {
      d = DateTime.fromMillisecondsSinceEpoch(raw as int);
    }
    return ScheduleDto(
      date: d,
      isCompleted: j['is_completed'] ?? j['isCompleted'] ?? false,
      callHour: j['call_hour'] ?? j['callHour'],
      callMinute: j['call_minute'] ?? j['callMinute'],
      durationMinutes: j['duration'] ?? j['duration_minutes'] ?? j['durationMinutes'],
    );
  }
}

class ScheduleApi {
  final Dio _dio = ApiClient().dio;

  Future<List<ScheduleDto>> fetchMonth({required int year, required int month}) async {
    final resp = await _dio.get('/schedules', queryParameters: {'year': year, 'month': month});
    final data = resp.data is List ? resp.data as List : (resp.data['items'] as List);
    return data.map((e) => ScheduleDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Response> fetchSettings() async {
    return _dio.get('/schedule-settings');
  }
}
