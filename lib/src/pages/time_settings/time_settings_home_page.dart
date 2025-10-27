import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/time_settings_controller.dart';
import '../../models/call_time.dart';
import '../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../widgets/time_row_tile.dart';
import 'time_add_sheet.dart';

class TimeSettingsHomePage extends GetView<TimeSettingsController> {
  const TimeSettingsHomePage({super.key});

  String _timeLabel(TimeOfDay t) {
    final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? '오전' : '오후';
    return '$ampm $h12:$mm';
  }

  String _weekLabel(Set<int> ws) {
    final names = ['월','화','수','목','금','토','일'];
    final list = ws.toList()..sort();
    return list.map((w) => names[w-1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전화', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(p.bgHeader.red, p.bgHeader.green, p.bgHeader.blue, 0.3),
        foregroundColor: p.typo900,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,),
          onPressed: () => Get.back(),
          color: p.typo900,
        ),
      ),
      body: Obx(() {
        final items = controller.callTimes;
        if (items.isEmpty) {
          return Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '언제 전화할까요?\n',
                style: TextStyle(color: p.typo800, fontWeight: FontWeight.w700, fontSize: 18, height: 1.40,),
                children: [
                  TextSpan(
                    text: '아래 추가 버튼을 누르고\n전화 시간을 설정해주세요',
                    style: TextStyle(color: p.typo300, fontWeight: FontWeight.w500, fontSize: 16, height: 1.62, letterSpacing: -0.10,),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final ct = items[i];
            return TimeRowTile(
              weekText: _weekLabel(ct.weekdays),
              timeText: _timeLabel(ct.time),
              onTap: () => Get.toNamed('${Routes.timeEdit}?id=${ct.id}'),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton( // + 버튼
        backgroundColor: p.typo900,
        shape: const CircleBorder(),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: p.bgFilled,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => const TimeAddSheet(),
          );
        },
        child: Icon(Icons.add, color: p.bgEmpty),
      ),
    );
  }
}