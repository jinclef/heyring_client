// lib/src/services/schedule_api.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_model.dart';
import 'api_client.dart';

class ScheduleApi {
  final _api = ApiClient.I;

  // 스케줄 목록 조회
  Future<List<Schedule>> fetchSchedules({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 200,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
      };

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _api.dio.get(
        '/schedules/',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((json) => Schedule.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch schedules error: $e');
      // 401 에러는 이미 인터셉터에서 처리됨
      return [];
    }
  }

  // 단일 스케줄 생성
  Future<Schedule?> createSchedule({
    required DateTime date,
    required TimeOfDay startTime,
    TimeOfDay? endTime,
    int? duration,
  }) async {
    try {
      final response = await _api.dio.post(
        '/schedules/',
        data: {
          'date': date.toIso8601String().split('T')[0],
          'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
          if (endTime != null)
            'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          if (duration != null) 'duration': duration,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return Schedule.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Create schedule error: $e');
      rethrow;
    }
  }

  // 스케줄 수정
  Future<Schedule?> updateSchedule({
    required int scheduleId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (startTime != null) {
        data['start_time'] = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      }
      if (endTime != null) {
        data['end_time'] = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      }
      if (status != null) {
        data['status'] = status;
      }

      final response = await _api.dio.put(
        '/schedules/$scheduleId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Schedule.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Update schedule error: $e');
      rethrow;
    }
  }

  // 스케줄 건너뛰기
  Future<bool> skipSchedule(int scheduleId) async {
    try {
      final response = await _api.dio.post('/schedules/$scheduleId/skip');
      return response.statusCode == 200;
    } catch (e) {
      print('Skip schedule error: $e');
      return false;
    }
  }

  // 스케줄 복원
  Future<bool> restoreSchedule(int scheduleId) async {
    try {
      final response = await _api.dio.post('/schedules/$scheduleId/restore');
      return response.statusCode == 200;
    } catch (e) {
      print('Restore schedule error: $e');
      return false;
    }
  }

  // 스케줄 삭제
  Future<bool> deleteSchedule(int scheduleId) async {
    try {
      final response = await _api.dio.delete('/schedules/$scheduleId');
      return response.statusCode == 200;
    } catch (e) {
      print('Delete schedule error: $e');
      return false;
    }
  }
}