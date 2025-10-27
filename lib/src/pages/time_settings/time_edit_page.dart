import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_settings_controller.dart';
import '../../widgets/cupertino_time_picker.dart';
import '../../widgets/day_chip.dart';
import '../../../theme/palette.dart';

class TimeEditPage extends StatefulWidget {
  final String callTimeId;
  const TimeEditPage({super.key, required this.callTimeId});

  @override
  State<TimeEditPage> createState() => _TimeEditPageState();
}

class _TimeEditPageState extends State<TimeEditPage> {
  late TimeSettingsController timeC;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late TimeOfDay _origTime;
  late Set<int> _origWeekdays;

  bool get changed => _time != _origTime || _weekdays.length != _origWeekdays.length || !_weekdays.containsAll(_origWeekdays);

  @override
  void initState() {
    super.initState();
    timeC = Get.find<TimeSettingsController>();
    final ct = timeC.callTimes.firstWhere((e) => e.id == widget.callTimeId);
    _time = ct.time;
    _weekdays = {...ct.weekdays};
    _origTime = ct.time;
    _origWeekdays = {...ct.weekdays};
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전화 변경', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: BackButton(color: p.typo900),
        backgroundColor: p.bgEmpty, surfaceTintColor: p.bgEmpty,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('시간', style: TextStyle(color: p.typo900, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TimePickerWheel(initial: _time, onChanged: (t) => setState(() => _time = t)),
          const SizedBox(height: 16),
          Text('반복', style: TextStyle(color: p.typo900, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(7, (i) {
              final w = i+1;
              final taken = timeC.isWeekdayTaken(w, exceptId: widget.callTimeId);
              final selected = _weekdays.contains(w);
              return DayChip(
                weekday: w,
                selected: selected,
                disabled: taken && !selected,
                onTap: () {
                  setState(() {
                    if (selected) _weekdays.remove(w);
                    else if (!taken) _weekdays.add(w);
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: changed ? () {
                timeC.updateTime(widget.callTimeId, _time);
                timeC.updateWeekdays(widget.callTimeId, _weekdays);
                Get.back();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.typo900, disabledBackgroundColor: p.stroke200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text('저장', style: TextStyle(color: p.bgEmpty)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                timeC.remove(widget.callTimeId);
                Get.back();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: p.stroke300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text('삭제', style: TextStyle(color: p.typo900)),
            ),
          ),
        ],
      ),
    );
  }
}
