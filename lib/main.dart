import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'theme/palette.dart';
import 'src/routes/app_routes.dart';
import 'src/routes/app_pages.dart';
import 'src/bindings/initial_binding.dart';
import 'src/services/storage_service.dart';
import 'src/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light, // iOS: 밝은 배경에 어두운 텍스트
      statusBarIconBrightness: Brightness.dark, // Android
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 1) StorageService를 가장 먼저 초기화 & 주입
  await Get.putAsync<StorageService>(
        () async => await StorageService().init(),
    permanent: true,
  );

  // 2) 테마 컨트롤러 주입
  Get.put(ThemeController(), permanent: true);

  // 3) 초기 DI 바인딩 (AuthController 등)
  InitialBinding().dependencies();

  // 4) 초기 토큰 여부 확인 (네비게이션 호출은 하지 않음)
  final hasToken = await AuthService().hasToken();

  // 5) 앱 실행
  runApp(HeyringApp(loggedInInitially: hasToken));
}

/// 테마 전환 컨트롤러
class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  void setMode(ThemeMode m) {
    mode.value = m;
    Get.changeThemeMode(m);
    _updateSystemUI(m);
  }

  void toggle() {
    final isDark = (mode.value == ThemeMode.dark) ||
        (mode.value == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void _updateSystemUI(ThemeMode mode) {
    final brightness = mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: brightness == Brightness.dark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

class HeyringApp extends StatelessWidget {
  const HeyringApp({super.key, required this.loggedInInitially});

  final bool loggedInInitially;

  // 전역 폰트 지정
  static const _kFontFamily = 'Pretendard';
  static const _kFontFallback = <String>[
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

        // 초기 라우트: 토큰 유무로 결정 (여기서만 결정, 사전 네비게이션 호출 금지)
        initialRoute: loggedInInitially ? Routes.schedule : Routes.login,

        getPages: AppPages.pages,
      );
    });
  }
}