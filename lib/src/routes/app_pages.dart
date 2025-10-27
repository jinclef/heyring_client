import 'package:get/get.dart';
import '../controllers/schedule_controller.dart';
import '../pages/login_page.dart';
import '../pages/schedule_page.dart';
import '../pages/time_settings/time_settings_home_page.dart';
import '../pages/time_settings/time_edit_page.dart';
import '../bindings/initial_binding.dart';
import '../controllers/time_settings_controller.dart';
import '../routes/app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      binding: InitialBinding(),
    ),
    // lib/src/routes/app_pages.dart
    GetPage(
      name: Routes.schedule,
      page: () => const SchedulePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ScheduleController>(() => ScheduleController());
      }),
      // 페이지 전환될 때마다 실행
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.timeSettingsHome,
      page: () => const TimeSettingsHomePage(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: Routes.timeEdit,
      page: () {
        final id = Get.parameters['id']!;
        return TimeEditPage(callTimeId: id);
      },
      binding: BindingsBuilder(() {
        // 공용 컨트롤러 사용
        Get.put(TimeSettingsController(), permanent: true);
      }),
    ),
  ];
}
