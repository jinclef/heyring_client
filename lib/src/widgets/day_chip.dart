import 'package:flutter/material.dart';
import '../../theme/palette.dart';

class DayChip extends StatelessWidget {
  final int weekday; // 1~7 (월~일)
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const DayChip({
    super.key,
    required this.weekday,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  String get label => const ['월','화','수','목','금','토','일'][weekday-1];

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;
    final bg = disabled
        ? p.stroke100
        : (selected ? p.typo900 : p.stroke100);
    final fg = disabled
        ? p.typo800
        : (selected ? p.bgEmpty : p.typo900);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.1 : 1.0,
        child: Container(
          width: 42, height: 42,
          padding: const EdgeInsets.all(10),
          decoration: ShapeDecoration(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: fg, fontSize: 14)),
        ),
      ),
    );
  }
}
