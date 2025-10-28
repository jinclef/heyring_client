// lib/src/pages/time_settings/time_edit_page.dart - iOS SafeArea 추가
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_settings_controller.dart';
import '../../widgets/cupertino_time_picker.dart';
import '../../widgets/day_chip.dart';
import '../../../theme/palette.dart';

class TimeEditSheet extends StatefulWidget {
  final String callTimeId;
  const TimeEditSheet({super.key, required this.callTimeId});

  @override
  State<TimeEditSheet> createState() => _TimeEditSheetState();
}

class _TimeEditSheetState extends State<TimeEditSheet> {
  late TimeSettingsController timeC;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late TimeOfDay _origTime;
  late Set<int> _origWeekdays;

  bool get changed =>
      _time != _origTime ||
          _weekdays.length != _origWeekdays.length ||
          !_weekdays.containsAll(_origWeekdays);

  @override
  void initState() {
    super.initState();
    timeC = Get.find<TimeSettingsController>();
    final ct = timeC.callTimes.firstWhere((e) => e.uniqueKey == widget.callTimeId);

    _time = ct.time;
    _weekdays = {...ct.weekdays};
    _origTime = ct.time;
    _origWeekdays = {...ct.weekdays};
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;
    final maxH = MediaQuery.of(context).size.height * 0.95;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: bottomInset + 30,
          top: 12,
        ),
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: ShapeDecoration(
          color: p.bgFilled,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x14121212),
              blurRadius: 20,
              offset: Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  // 닫기 버튼 (왼쪽)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                  ),

                  // 가운데 타이틀
                  const Expanded(
                    child: Center(
                      child: Text(
                        '전화변경',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // 삭제 버튼 (오른쪽)
                  Obx(() {
                    return TextButton(
                      onPressed: timeC.isLoading.value
                          ? null
                          : () async {
                        await timeC.remove(widget.callTimeId);
                        Get.back();
                      },
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: p.stroke200,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: TimePickerWheel(
                initial: _time,
                onChanged: (t) => setState(() => _time = t),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '반복',
                      style: TextStyle(
                        color: p.typo900,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final w = i + 1;
                      final selected = _weekdays.contains(w);
                      return DayChip(
                        weekday: w,
                        selected: selected,
                        disabled: false, // 모든 요일 선택 가능
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _weekdays.remove(w);
                            } else {
                              _weekdays.add(w);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(() {
                final loading = timeC.isLoading.value;
                return ElevatedButton(
                  onPressed: (changed && !loading)
                      ? () async {
                    await timeC.updateCallTime(
                      widget.callTimeId,
                      newTime: _time != _origTime ? _time : null,
                      newWeekdays: !_weekdays.containsAll(_origWeekdays) ||
                          _weekdays.length != _origWeekdays.length
                          ? _weekdays
                          : null,
                    );
                    Get.back();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.typo900,
                    disabledBackgroundColor: p.stroke200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    '저장',
                    style: TextStyle(
                      color: p.bgEmpty,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}