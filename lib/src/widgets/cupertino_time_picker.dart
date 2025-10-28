// lib/src/widgets/cupertino_time_picker.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/palette.dart';

class TimePickerWheel extends StatefulWidget {
  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onChanged;

  const TimePickerWheel({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<TimePickerWheel> createState() => _TimePickerWheelState();
}

class _TimePickerWheelState extends State<TimePickerWheel> {
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  // 무한 스크롤 초기화용 오프셋
  static const int _hourOffset = 10000;
  static const int _minuteOffset = 10000;

  // 11↔12 경계 체크용: 직전 "시" 인덱스
  late int _prevHourIndex;

  @override
  void initState() {
    super.initState();
    final initHour12 = widget.initial.hourOfPeriod == 0 ? 12 : widget.initial.hourOfPeriod;
    final initMinute = widget.initial.minute;
    final initPeriod = widget.initial.period == DayPeriod.am ? 0 : 1;

    // 시: 1~12를 0~11 인덱스로 변환 후 offset 적용
    final hourIndex = initHour12 - 1;  // 1->0, 2->1, ..., 12->11

    // offset을 12로 나눈 나머지가 0이 되도록 조정
    // _hourOffset % 12 = 4 이므로, 4를 빼서 12의 배수로 만듦
    final adjustedHourOffset = _hourOffset - (_hourOffset % 12);

    // offset을 60으로 나눈 나머지가 0이 되도록 조정
    // _minuteOffset % 60 = 40 이므로, 40을 빼서 60의 배수로 만듦
    final adjustedMinuteOffset = _minuteOffset - (_minuteOffset % 60);

    hourController = FixedExtentScrollController(
      initialItem: adjustedHourOffset + hourIndex,
    );

    minuteController = FixedExtentScrollController(
      initialItem: adjustedMinuteOffset + initMinute,
    );

    periodController = FixedExtentScrollController(
      initialItem: initPeriod,
    );

    _prevHourIndex = hourController.initialItem;

    // 첫 렌더 직후 현재 선택값을 부모로 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitTimeFromControllers());
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    periodController.dispose();
    super.dispose();
  }

  // 현재 선택 인덱스에서 직접 계산해서 전달
  void _emitTimeFromControllers() {
    final hourIndex   = hourController.selectedItem;   // 0..∞
    final minuteIndex = minuteController.selectedItem; // 0..∞
    final periodIndex = periodController.selectedItem; // 0 or 1

    final hour12 = (hourIndex % 12) + 1; // 1..12
    final minute = minuteIndex % 60;
    final isPm   = (periodIndex % 2) == 1;

    int h24 = (hour12 == 12 ? 0 : hour12);
    if (isPm) h24 += 12;

    widget.onChanged(TimeOfDay(hour: h24, minute: minute));
  }

  String _getAmPmText(int index) {
    final m = MaterialLocalizations.of(context);
    return index == 0 ? m.anteMeridiemAbbreviation : m.postMeridiemAbbreviation;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    // 기본 치수
    const double kItemExtent   = 44;            // 아이템 높이
    const double kViewport     = kItemExtent*3; // 132: 3줄 뷰포트
    const double ampmWidth     = 72;            // '오전/오후'
    const double hourWidth     = 48;            // 시
    const double minuteWidth   = 56;            // 분
    const double gap           = 6;
    const double highlightWidth = ampmWidth + gap + hourWidth + gap + minuteWidth;

    const TextStyle kPickerTextStyle = TextStyle(
      fontSize: 22,
      color: CupertinoColors.label,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      height: kViewport,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: p.stroke100),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가운데 선택 하이라이트 바: 실제 Row 폭만큼만 칠함
          Align(
            alignment: Alignment.center,
            child: Container(
              width: highlightWidth,
              height: kItemExtent,
              decoration: BoxDecoration(
                color: p.stroke100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AM/PM
              SizedBox(
                width: ampmWidth,
                child: CupertinoPicker.builder(
                  backgroundColor: Colors.transparent,
                  selectionOverlay: const SizedBox.shrink(),
                  scrollController: periodController,
                  itemExtent: kItemExtent,
                  useMagnifier: true,
                  magnification: 1.05,
                  childCount: 2,
                  onSelectedItemChanged: (_) => _emitTimeFromControllers(),
                  itemBuilder: (_, i) => Center(
                    child: Text(_getAmPmText(i), style: kPickerTextStyle),
                  ),
                ),
              ),

              const SizedBox(width: gap),

              // 시 (무한)
              SizedBox(
                width: hourWidth,
                child: CupertinoPicker.builder(
                  backgroundColor: Colors.transparent,
                  selectionOverlay: const SizedBox.shrink(),
                  scrollController: hourController,
                  itemExtent: kItemExtent,
                  useMagnifier: true,
                  magnification: 1.05,
                  childCount: 1 << 31,
                  onSelectedItemChanged: (index) {
                    final prevHour = (_prevHourIndex % 12) + 1;
                    final currHour = (index % 12) + 1;
                    final crossed = (prevHour == 11 && currHour == 12) ||
                        (prevHour == 12 && currHour == 11);
                    if (crossed && periodController.hasClients) {
                      final nextPeriod = (periodController.selectedItem + 1) % 2;
                      periodController.animateToItem(
                        nextPeriod,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                      );
                    }
                    _prevHourIndex = index;
                    _emitTimeFromControllers();
                  },
                  itemBuilder: (_, i) => Center(
                    child: Text('${(i % 12) + 1}', style: kPickerTextStyle),
                  ),
                ),
              ),

              const SizedBox(width: gap),

              // 분 (무한)
              SizedBox(
                width: minuteWidth,
                child: CupertinoPicker.builder(
                  backgroundColor: Colors.transparent,
                  selectionOverlay: const SizedBox.shrink(),
                  scrollController: minuteController,
                  itemExtent: kItemExtent,
                  useMagnifier: true,
                  magnification: 1.05,
                  childCount: 1 << 31,
                  onSelectedItemChanged: (_) => _emitTimeFromControllers(),
                  itemBuilder: (_, i) => Center(
                    child: Text((i % 60).toString().padLeft(2, '0'), style: kPickerTextStyle),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}