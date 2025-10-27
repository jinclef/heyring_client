// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'theme/palette.dart';
import 'src/routes/app_routes.dart';
import 'src/routes/app_pages.dart';
import 'src/controllers/auth_controller.dart';
import 'src/bindings/initial_binding.dart';
import 'src/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  StorageService를 가장 먼저 초기화 & 주입 (await 필수)
  await Get.putAsync<StorageService>(
    () async => await StorageService().init(),
    permanent: true,
  );

  Get.put(ThemeController(), permanent: true);

  // 초기 DI 바인딩
  InitialBinding().dependencies();

  // 자동 로그인 체크
  final auth = Get.find<AuthController>();
  await auth.tryAutoLogin();

  runApp(const HeyringApp());
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

class HeyringApp extends StatelessWidget {
  const HeyringApp({super.key});

  // 전역 폰트 지정
  static const _kFontFamily = 'Pretendard';
  static const _kFontFallback = <String>[
    // 플랫폼별 폴백 (없어도 되지만 권장)
    'Apple SD Gothic Neo', // iOS/macOS
    'Noto Sans CJK KR',    // 일부 안드로이드/윈도우
    'Noto Sans KR',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  @override
  Widget build(BuildContext context) {
    final themeC = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        title: '헤이링',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // 라이트 테마
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.light.bgFilled,
          extensions: const [AppPalette.light],

          fontFamily: _kFontFamily,
          fontFamilyFallback: _kFontFallback,

          textTheme: Typography.blackMountainView.apply(
            bodyColor: AppPalette.light.typo950,
            displayColor: AppPalette.light.typo950,
          ),
        ),

        // 다크 테마
        darkTheme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.dark.bgFilled,
          extensions: const [AppPalette.dark],

          fontFamily: _kFontFamily,
          fontFamilyFallback: _kFontFallback,

          textTheme: Typography.whiteMountainView.apply(
            bodyColor: AppPalette.dark.typo200,
            displayColor: AppPalette.dark.typo200,
          ),
        ),

        themeMode: themeC.mode.value, // GetX로 모드 제어

        initialRoute: Get.find<AuthController>().isLoggedIn.value
            ? Routes.schedule
            : Routes.login,
        getPages: AppPages.pages,
      );
    });
  }
}