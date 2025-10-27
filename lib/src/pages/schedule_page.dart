// lib/src/pages/schedule_page.dart - WidgetsBindingObserver 추가
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/palette.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/time_settings_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/schedule_item_tile.dart';

class SchedulePage extends GetView<ScheduleController> with WidgetsBindingObserver {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    // 페이지가 보일 때마다 스크롤 실행
    WidgetsBinding.instance.addObserver(this);

    // 빌드 후 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.scrollToToday();
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 8),
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
            transform: Matrix4.rotationY(math.pi),
            child: const Icon(Icons.logout),
          ),
          onPressed: () async {
            Get.dialog(
              const Center(child: CircularProgressIndicator()),
              barrierDismissible: false,
            );

            await Get.find<AuthController>().logoutDevice();
            Get.back();
          },
        ),
        title: Obx(() => Text(
          controller.displayMonthYear,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFBEBEBE)),
            onPressed: () async {
              // 설정 페이지로 이동하기 전에 최신 데이터 가져오기
              if (Get.isRegistered<TimeSettingsController>()) {
                await Get.find<TimeSettingsController>().fetchFromServer();
              }

              await Get.toNamed(Routes.timeSettingsHome);

              // 돌아왔을 때 스케줄 새로고침 및 오늘로 스크롤
              await controller.refresh();
              Future.delayed(const Duration(milliseconds: 100), () {
                controller.scrollToToday();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = controller.days;

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.separated(
                  controller: controller.scrollController,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: p.stroke100),
                  itemBuilder: (_, i) {
                    return ScheduleItemTile(
                      date: items[i].date,
                      callAt: items[i].callAt,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}