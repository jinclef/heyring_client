// lib/src/services/schedule_setting_api.dart
import 'package:get/get.dart';
import '../models/schedule_setting_model.dart';
import 'api_client.dart';

class ScheduleSettingApi {
  final _api = ApiClient.I;

  // 설정 목록 조회
  Future<List<ScheduleSetting>> fetchSettings() async {
    try {
      final response = await _api.dio.get('/settings/');

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((json) => ScheduleSetting.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch settings error: $e');
      return [];
    }
  }

  // 설정 생성
  Future<ScheduleSetting?> createSetting({
    required List<String> weekdays,
    required List<String> startTimes,
    int duration = 60,
  }) async {
    try {
      final response = await _api.dio.post(
        '/settings/',
        data: {
          'weekdays': weekdays,
          'start_times': startTimes,
          'duration': duration,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return ScheduleSetting.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Create setting error: $e');
      rethrow;
    }
  }

  // 설정 수정 (요일과 시간 모두 변경 가능)
  Future<ScheduleSetting?> updateSetting({
    required int settingId,
    List<String>? weekdays,
    List<String>? startTimes,
    int? duration,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (weekdays != null) data['weekdays'] = weekdays;
      if (startTimes != null) data['start_times'] = startTimes;
      if (duration != null) data['duration'] = duration;

      final response = await _api.dio.put(
        '/settings/$settingId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ScheduleSetting.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Update setting error: $e');
      rethrow;
    }
  }

  // 설정 삭제
  Future<bool> deleteSetting(int settingId) async {
    try {
      final response = await _api.dio.delete('/settings/$settingId');
      return response.statusCode == 200;
    } catch (e) {
      print('Delete setting error: $e');
      return false;
    }
  }
}