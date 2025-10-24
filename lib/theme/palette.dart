// lib/theme/palette.dart
import 'package:flutter/material.dart';

/// 색 토큰: 디자인 용어 그대로 묶음(typo / stroke / dot / fill)
/// - 명도 감각을 맞추기 위해 대략적인 단계 번호를 붙였습니다.
class AppPalette extends ThemeExtension<AppPalette> {
  // === typo (텍스트/아이콘 등) ===
  final Color typo950; // 가장 진함
  final Color typo900;
  final Color typo800;
  final Color typo600;
  final Color typo400;
  final Color typo200; // 가장 연함

  // === stroke (선/구분선) ===
  final Color stroke100; // 가장 연함
  final Color stroke200;
  final Color stroke300; // 중간
  final Color stroke400; // 가장 진함

  // === dot (포인트/상태 점 등) ===
  final Color dotPrimary;
  final Color dotMuted;

  // === bg (배경) ===
  final Color bgFilled;
  final Color bgEmpty;

  const AppPalette({
    required this.typo950,
    required this.typo900,
    required this.typo800,
    required this.typo600,
    required this.typo400,
    required this.typo200,
    required this.stroke100,
    required this.stroke200,
    required this.stroke300,
    required this.stroke400,
    required this.dotPrimary,
    required this.dotMuted,
    required this.bgFilled,
    required this.bgEmpty,
  });

  /// 라이트 팔레트
  static const light = AppPalette(
    // typo
    typo950: Color(0xFF242424),
    typo900: Color(0xFF2A2A2B),
    typo800: Color(0xFF2E2E2E),
    typo600: Color(0xFF73727C),
    typo400: Color(0xFF959595),
    typo200: Color(0xFFD9D9D9),

    // stroke (밝은 → 진한)
    stroke100: Color(0xFFEFEFEF),
    stroke200: Color(0xFFD7D7D7),
    stroke300: Color(0xFFBBBBBB),
    stroke400: Color(0xFF73727C), // 필요시 다른 값으로 교체 가능

    // dot
    dotPrimary: Color(0xFFFF4242),
    dotMuted: Color(0xFFD7D7D7),

    // fill
    bgFilled: Color(0xFFF9F9F9),
    bgEmpty: Color(0xFFFFFFFF),
  );

  /// 다크 테마가 필요하면 여기서 조정하세요(간단히 스왑/톤다운 예시)
  /// 다크 팔레트
  static const dark = AppPalette(
    // typo (텍스트 계열 → 반전)
    typo950: Color(0xFFF9F9F9),
    typo900: Color(0xFFD9D9D9),
    typo800: Color(0xFF959595),
    typo600: Color(0xFFBBBBBB),
    typo400: Color(0xFFD7D7D7),
    typo200: Color(0xFF2A2A2B),

    // stroke (선 → 반전)
    stroke100: Color(0xFF2A2A2B),
    stroke200: Color(0xFF2E2E2E),
    stroke300: Color(0xFF3A3A3A),
    stroke400: Color(0xFF4A4A4A),

    // dot (빨강은 그대로, 회색만 반전 톤)
    dotPrimary: Color(0xFFFF4242),
    dotMuted: Color(0xFF73727C),

    // 배경 (filled=어두운, empty=검정에 가까움)
    bgFilled: Color(0xFF242424),
    bgEmpty: Color(0xFF000000),
  );


  @override
  AppPalette copyWith({
    Color? typo950,
    Color? typo900,
    Color? typo800,
    Color? typo600,
    Color? typo400,
    Color? typo200,
    Color? stroke100,
    Color? stroke200,
    Color? stroke300,
    Color? stroke400,
    Color? dotPrimary,
    Color? dotMuted,
    Color? bgFilled,
    Color? bgEmpty,
  }) {
    return AppPalette(
      typo950: typo950 ?? this.typo950,
      typo900: typo900 ?? this.typo900,
      typo800: typo800 ?? this.typo800,
      typo600: typo600 ?? this.typo600,
      typo400: typo400 ?? this.typo400,
      typo200: typo200 ?? this.typo200,
      stroke100: stroke100 ?? this.stroke100,
      stroke200: stroke200 ?? this.stroke200,
      stroke300: stroke300 ?? this.stroke300,
      stroke400: stroke400 ?? this.stroke400,
      dotPrimary: dotPrimary ?? this.dotPrimary,
      dotMuted: dotMuted ?? this.dotMuted,
      bgFilled: bgFilled ?? this.bgFilled,
      bgEmpty: bgEmpty ?? this.bgEmpty,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color _l(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppPalette(
      typo950: _l(typo950, other.typo950),
      typo900: _l(typo900, other.typo900),
      typo800: _l(typo800, other.typo800),
      typo600: _l(typo600, other.typo600),
      typo400: _l(typo400, other.typo400),
      typo200: _l(typo200, other.typo200),
      stroke100: _l(stroke100, other.stroke100),
      stroke200: _l(stroke200, other.stroke200),
      stroke300: _l(stroke300, other.stroke300),
      stroke400: _l(stroke400, other.stroke400),
      dotPrimary: _l(dotPrimary, other.dotPrimary),
      dotMuted: _l(dotMuted, other.dotMuted),
      bgFilled: _l(bgFilled, other.bgFilled),
      bgEmpty: _l(bgEmpty, other.bgEmpty),
    );
  }
}

/// BuildContext에서 쉽게 꺼내 쓰기 위한 확장
extension AppPaletteX on BuildContext {
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
