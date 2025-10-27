import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/palette.dart';
// 프로젝트 경로에 맞게 조정하세요.
import 'hatch_overlay.dart' show HatchPainter;

class ScheduleItemTile extends StatelessWidget {
  final DateTime date;
  final TimeOfDay? callAt;

  const ScheduleItemTile({super.key, required this.date, required this.callAt});

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

    if (isCompleted) {
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
                  if (!isCompleted)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: p.dotMuted),
                      splashRadius: 20,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => CupertinoActionSheet(
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // 수정 로직
                                },
                                child: const Text('수정하기'),
                              ),
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // 삭제/비활성 로직
                                },
                                isDestructiveAction: true,
                                child: const Text('쉬어가기'),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                          ),
                        );
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
}
