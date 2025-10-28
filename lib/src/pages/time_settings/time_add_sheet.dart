// lib/src/pages/time_settings/time_add_sheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_settings_controller.dart';
import '../../widgets/cupertino_time_picker.dart';
import '../../widgets/day_chip.dart';
import '../../../theme/palette.dart';

class TimeAddSheet extends StatefulWidget {
  const TimeAddSheet({super.key});

  @override
  State<TimeAddSheet> createState() => _TimeAddSheetState();
}

class _TimeAddSheetState extends State<TimeAddSheet> {
  TimeOfDay _time = TimeOfDay.now();
  final Set<int> _weekdays = {};

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;
    final timeC = Get.find<TimeSettingsController>();
    final maxH = MediaQuery.of(context).size.height * 0.95;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      '전화추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
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
                  child: Text('반복', style: TextStyle(color: p.typo900, fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final w = i + 1;
                    final taken = timeC.isWeekdayTaken(w);
                    final selected = _weekdays.contains(w);
                    return DayChip(
                      weekday: w,
                      selected: selected,
                      disabled: taken && !selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _weekdays.remove(w);
                          } else {
                            if (!taken) _weekdays.add(w);
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
              return ElevatedButton(
                onPressed: (_weekdays.isEmpty || timeC.isLoading.value)
                    ? null
                    : () async {
                  await timeC.add(_time, _weekdays);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.typo900,
                  disabledBackgroundColor: p.stroke200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: timeC.isLoading.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    );
  }
}