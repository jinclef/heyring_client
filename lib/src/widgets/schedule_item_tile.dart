import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/palette.dart';
import '../controllers/schedule_controller.dart';
import 'cupertino_time_picker.dart';
import 'hatch_overlay.dart' show HatchPainter;

class ScheduleItemTile extends StatelessWidget {
  final DateTime date;
  final TimeOfDay? callAt;
  final int? scheduleId;
  final bool isSkipped;

  const ScheduleItemTile({
    super.key,
    required this.date,
    required this.callAt,
    this.scheduleId,
    this.isSkipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    final now = DateTime.now();
    final today = DateUtils.isSameDay(date, now);
    final pastDay = date.isBefore(DateTime(now.year, now.month, now.day));
    final hasCall = callAt != null;

    bool isTodayPastTime() {
      if (!today || !hasCall) return false;
      final n = TimeOfDay.now();
      final nMin = n.hour * 60 + n.minute;
      final cMin = callAt!.hour * 60 + callAt!.minute;
      return cMin <= nMin;
    }

    // 빗금 조건
    final isCompleted = (pastDay && hasCall) || isTodayPastTime();

    // === 스타일 결정 (기존 로직 유지) ===
    Color rowBg = p.bgEmpty;
    TextStyle timeStyle = TextStyle(color: p.typo800);
    TextStyle dayStyle = TextStyle(
      color: p.typo400,
      fontWeight: today ? FontWeight.w700 : FontWeight.w500,
    );

    if (isCompleted || isSkipped) {
      rowBg = pastDay || today ? p.bgEmpty : p.bgFilled;
      timeStyle = TextStyle(color: p.stroke200);
      dayStyle = TextStyle(color: p.stroke200);
    } else if (today) {
      rowBg = p.typo800;
      timeStyle = TextStyle(color: hasCall ? p.bgEmpty : p.bgFilled, fontWeight: FontWeight.w500);
      dayStyle = TextStyle(color: p.bgEmpty);
    } else if (hasCall) {
      rowBg = p.bgFilled;
      timeStyle = TextStyle(color: p.typo900, fontWeight: FontWeight.w500);
      dayStyle = TextStyle(color: p.typo900);
    }

    String timeLabel() {
      if (isSkipped){
        if(today) return "예정된 전화 없음";
        return "휴식";
      }
      if (!hasCall) return ' ';
      final t = callAt!;
      final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final mm = t.minute.toString().padLeft(2, '0');
      final ampm = t.period == DayPeriod.am ? '오전' : '오후';
      return '$ampm $h12:$mm';
    }

    final content = Container(
      color: rowBg,
      child: Row(
        children: [
          // 왼쪽 날짜 칸
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(width: 1, color: p.stroke100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    today ? "오늘" : const ['월','화','수','목','금','토','일'][date.weekday - 1],
                    textAlign: TextAlign.center,
                    style: dayStyle.copyWith(fontSize: 10, height: 1.5, letterSpacing: -0.10),
                  ),
                ),
                SizedBox(
                  width: 22,
                  child: Text('${date.day}', textAlign: TextAlign.center, style: dayStyle.copyWith(fontSize: 16, height: 1.62, letterSpacing: -0.10)),
                ),
              ],
            ),
          ),

          // 가운데 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasCall ? timeLabel() : (today ? "예정된 전화 없음" : ""),
                            style: timeStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (today && hasCall && !isCompleted)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: p.dotPrimary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                  if (hasCall && scheduleId != null && !isCompleted)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: p.dotMuted),
                      splashRadius: 20,
                      onPressed: () {
                        _showActionSheet(context, scheduleId!);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 빗금을 "한 번만" 위에 얹기: 중첩 방지
    return CustomPaint(
      foregroundPainter: isCompleted
          ? HatchPainter(
        lineColor: Colors.black.withOpacity(0.10),
        thickness: 1.2,
        gap: 7,
        angleRad: 45 * math.pi / 180,
      )
          : null,
      child: content,
    );
  }

  // lib/src/widgets/schedule_item_tile.dart의 _showActionSheet 메서드 수정

  void _showActionSheet(BuildContext context, int scheduleId) {
    final controller = Get.find<ScheduleController>();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, scheduleId);
            },
            child: const Text('수정하기'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);

              // 로딩 표시
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              final success = isSkipped
              ? await controller.restoreSchedule(scheduleId)
              : await controller.skipSchedule(scheduleId);

              Get.back(); // 로딩 닫기

              if (success) {
                // _showSuccessBannerSafe('전화 시간이 수정되었어요.');
              } else {
                Get.snackbar(
                  '오류',
                  '일정 건너뛰기에 실패했습니다',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            isDestructiveAction: true,
            child: isSkipped ? Text("전화받기") : Text('쉬어가기'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, int scheduleId) {
    final controller = Get.find<ScheduleController>();
    final p = context.appPalette;
    TimeOfDay selectedTime = callAt ?? TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TimePickerWheel 사용
              SizedBox(
                height: 200,
                child: TimePickerWheel(
                  initial: selectedTime,
                  onChanged: (time) {
                    selectedTime = time;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    // 로딩 표시
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    final success = await controller.updateScheduleTime(
                      scheduleId,
                      selectedTime,
                    );

                    Get.back(); // 로딩 닫기

                    if (success) {
                      _showSuccessBannerSafe('전화 시간이 수정되었어요.');
                    } else {
                      Get.snackbar(
                        '오류',
                        '일정 수정에 실패했습니다',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.typo900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: p.bgEmpty,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessBannerSafe(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        messageText: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF2E2E2E), // stroke200
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        snackPosition: SnackPosition.TOP,
      ),
    );
  }
}
