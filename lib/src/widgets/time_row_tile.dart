// time_row_tile.dart
import 'package:flutter/material.dart';
import '../../../theme/palette.dart';

class TimeRowTile extends StatelessWidget {
  final String weekText;
  final String timeText;
  final VoidCallback? onTap;

  const TimeRowTile({
    super.key,
    required this.weekText,
    required this.timeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.appPalette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13.5),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: p.stroke100,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 왼쪽: 요일 + 시간 텍스트
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekText,
                  style: TextStyle(
                    color: p.typo900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: TextStyle(
                    color: p.typo600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            // 오른쪽: 화살표
            Icon(Icons.chevron_right, color: p.typo400, size: 24,),
          ],
        ),
      ),
    );
  }
}
