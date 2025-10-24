// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/palette.dart'; // 방금 만든 AppPalette 파일

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ThemeController(), permanent: true);
  runApp(const MyApp());
}

/// 테마 전환 컨트롤러
class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  void setMode(ThemeMode m) {
    mode.value = m;
    Get.changeThemeMode(m);
  }

  void toggle() {
    final isDark = (mode.value == ThemeMode.dark) ||
        (mode.value == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeC = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        title: 'Palette Demo',
        debugShowCheckedModeBanner: false,
        // 라이트 테마에 AppPalette.light 주입
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.light.bgFilled,
          extensions: const [AppPalette.light],
        ),
        // 다크 테마에 AppPalette.dark 주입
        darkTheme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.dark.bgFilled,
          extensions: const [AppPalette.dark],
        ),
        themeMode: themeC.mode.value, // GetX로 모드 제어
        home: const HomePage(),
      );
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette; // 확장으로 바로 팔레트 접근
    final themeC = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.bgEmpty,
        title: Text('AppPalette x GetX', style: TextStyle(color: p.typo900)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.bgEmpty,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.stroke200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('타이틀(typo900)', style: TextStyle(color: p.typo900, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('본문(typo600)', style: TextStyle(color: p.typo600)),
                const SizedBox(height: 8),
                Divider(color: p.stroke100),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: p.dotPrimary, size: 12),
                    const SizedBox(width: 8),
                    Text('상태: 활성', style: TextStyle(color: p.typo800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: themeC.toggle,
            style: FilledButton.styleFrom(
              backgroundColor: p.dotPrimary, // 포인트 컬러도 재사용 가능
              foregroundColor: p.bgEmpty,
            ),
            child: const Text('라이트/다크 토글'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: () => themeC.setMode(ThemeMode.light), child: const Text('Light')),
              OutlinedButton(onPressed: () => themeC.setMode(ThemeMode.dark), child: const Text('Dark')),
              OutlinedButton(onPressed: () => themeC.setMode(ThemeMode.system), child: const Text('System')),
            ],
          ),
        ],
      ),
      backgroundColor: p.bgFilled,
    );
  }
}