import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/palette.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    return Scaffold(
      backgroundColor: p.bgEmpty,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text('Heyring', style: TextStyle(fontSize: 28, color: p.typo900, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('편하고 부담없는\nAI 전화영어', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: p.typo600, height: 1.4)),
              const Spacer(),
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  hintText: '사용자 id 입력란 (예: hypernova)',
                  hintStyle: TextStyle(color: p.typo400),
                  filled: true,
                  fillColor: context.appPalette.bgFilled,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.stroke200),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                    setState(() => loading = true);
                    final ok = await Get.find<AuthController>().login(idCtrl.text);
                    setState(() => loading = false);
                    if (!ok) {
                      Get.snackbar('로그인 실패', 'id를 확인해주세요');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.typo900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(loading ? '진입 중...' : '시작하기', style: TextStyle(color: p.bgEmpty, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
