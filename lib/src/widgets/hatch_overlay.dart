import 'dart:math' as math;
import 'package:flutter/material.dart';

class HatchOverlay extends StatelessWidget {
  const HatchOverlay({
    super.key,
    this.lineColor = const Color(0x33000000),
    this.thickness = 1.2,
    this.gap = 8.0,
    this.angleDeg = 45.0,
    this.borderRadius,
  });

  // ⬇️ 아래 painter에서 사용하려고 유지
  final Color lineColor;
  final double thickness;
  final double gap;
  final double angleDeg;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: HatchPainter(
          lineColor: lineColor,
          thickness: thickness,
          gap: gap,
          angleRad: angleDeg * math.pi / 180,
          borderRadius: borderRadius,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// 공개 painter (foregroundPainter로도 사용 가능)
class HatchPainter extends CustomPainter {
  HatchPainter({
    required this.lineColor,
    required this.thickness,
    required this.gap,
    required this.angleRad,
    this.borderRadius,
  });

  final Color lineColor;
  final double thickness;
  final double gap;
  final double angleRad;
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // 1) 먼저 현재 위젯 경계로 클리핑(넘침 방지)
    final rect = Offset.zero & size;
    if (borderRadius != null) {
      final rrect = borderRadius!.toRRect(rect);
      canvas.clipRRect(rrect);
    } else {
      canvas.clipRect(rect);
    }

    // 2) 사선 그리기
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = thickness
      ..isAntiAlias = true;

    canvas.save();

    // 중앙 기준 회전
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleRad);

    // 충분한 길이
    final span = math.sqrt(size.width * size.width + size.height * size.height);
    final step = gap + thickness;

    for (double x = -span; x <= span; x += step) {
      canvas.drawLine(Offset(x, -span), Offset(x, span), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(HatchPainter old) =>
      old.lineColor != lineColor ||
          old.thickness != thickness ||
          old.gap != gap ||
          old.angleRad != angleRad ||
          old.borderRadius != borderRadius;
}
