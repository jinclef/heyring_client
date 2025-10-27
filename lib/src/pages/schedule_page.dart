import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/palette.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/schedule_item_tile.dart';
import 'dart:math' as math;

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 8), // 블러 강도 조절
            child: Container(
              color: Color.fromRGBO(p.bgHeader.red, p.bgHeader.green, p.bgHeader.blue, 0.7),
            ),
          ),
        ),
        backgroundColor: Color.fromRGBO(p.bgHeader.red, p.bgHeader.green, p.bgHeader.blue, 0.3),
        foregroundColor: p.typo900,
        leading: IconButton(
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi), // 좌우 반전
            child: const Icon(Icons.logout),
          ),
          onPressed: () {
            Get.find<AuthController>().logout();
            Get.offAllNamed(Routes.login);
          },
        ),
        title: Obx(() => Text(controller.monthTitleKr(controller.currentMonth.value),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFBEBEBE),),
            onPressed: () => Get.toNamed(Routes.timeSettingsHome),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final items = controller.days;
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: p.stroke100),
                itemBuilder: (_, i) => ScheduleItemTile(
                  date: items[i].date,
                  callAt: items[i].callAt,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
