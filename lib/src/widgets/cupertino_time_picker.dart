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

    hourController   = FixedExtentScrollController(initialItem: _hourOffset   + (initHour12 - 1));
    minuteController = FixedExtentScrollController(initialItem: _minuteOffset +  initMinute);
    periodController = FixedExtentScrollController(initialItem: initPeriod);

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

  // 탭 방향에 따라 한 칸(또는 여러 칸) 이동시키는 UX용 헬퍼
  void _handleTap(
      Offset localPosition,
      double pickerHeight,
      FixedExtentScrollController controller,
      int totalItems, {
        required double itemExtent,
        bool isInfinite = false,
      }) {
    final double centerY = pickerHeight / 2;
    final double offset  = localPosition.dy - centerY;
    final int itemOffset = (offset / itemExtent).round();

    if (itemOffset != 0) {
      final int currentItem = controller.selectedItem;
      int targetItem = currentItem + itemOffset;
      if (!isInfinite) {
        targetItem = targetItem.clamp(0, totalItems - 1);
      }
      controller.animateToItem(
        targetItem,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
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
                child: GestureDetector(
                  onTapUp: (d) => _handleTap(
                    d.localPosition, kViewport, periodController, 2,
                    itemExtent: kItemExtent,
                  ),
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
              ),

              const SizedBox(width: gap),

              // 시 (무한)
              SizedBox(
                width: hourWidth,
                child: GestureDetector(
                  onTapUp: (d) => _handleTap(
                    d.localPosition, kViewport, hourController, 12,
                    itemExtent: kItemExtent, isInfinite: true,
                  ),
                  child: CupertinoPicker.builder(
                    backgroundColor: Colors.transparent,
                    selectionOverlay: const SizedBox.shrink(),
                    scrollController: hourController,
                    itemExtent: kItemExtent,
                    useMagnifier: true,
                    magnification: 1.05,
                    childCount: 1 << 31, // 충분히 큼(사실상 무한)
                    onSelectedItemChanged: (index) {
                      // 11↔12 경계에서 AM/PM 컨트롤러만 토글
                      final prevHour = (_prevHourIndex % 12) + 1;
                      final currHour = (index        % 12) + 1;
                      final crossed  = (prevHour == 11 && currHour == 12) ||
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
                      _emitTimeFromControllers(); // 항상 컨트롤러 인덱스 기반으로 전달
                    },
                    itemBuilder: (_, i) => Center(
                      child: Text('${(i % 12) + 1}', style: kPickerTextStyle),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: gap),

              // 분 (무한)
              SizedBox(
                width: minuteWidth,
                child: GestureDetector(
                  onTapUp: (d) => _handleTap(
                    d.localPosition, kViewport, minuteController, 60,
                    itemExtent: kItemExtent, isInfinite: true,
                  ),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
