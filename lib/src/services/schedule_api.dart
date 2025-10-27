import 'package:dio/dio.dart';
import 'api_client.dart';

class ScheduleDto {
  final DateTime date;
  final bool isCompleted;
  final int? callHour;
  final int? callMinute;

  ScheduleDto({
    required this.date,
    required this.isCompleted,
    this.callHour,
    this.callMinute,
  });

  factory ScheduleDto.fromJson(Map<String, dynamic> j) => ScheduleDto(
    date: DateTime.parse(j['date'] as String),
    isCompleted: (j['is_completed'] as bool?) ?? false,
    callHour: j['call_hour'] as int?,
    callMinute: j['call_minute'] as int?,
  );
}

class ScheduleApi {
  Future<List<ScheduleDto>> fetchMonth({required int year, required int month}) async {
    try {
      final res = await ApiClient.I.dio.get('/schedules', queryParameters: {
        'year': year,
        'month': month,
      });
      final data = (res.data as List).cast<Map<String, dynamic>>();
      return data.map(ScheduleDto.fromJson).toList();
    } on DioException catch (e) {
      // 401은 인터셉터가 처리함
      rethrow;
    }
  }
}
