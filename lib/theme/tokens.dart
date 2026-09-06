import 'package:flutter/material.dart';

/// saturn-mobile-client-flutter(lib/core/theme.dart)의 팔레트/반지름 값을
/// 그대로 옮겼다 — 두 앱이 같은 패밀리처럼 보이도록 토큰을 공유한다.
class AppColors {
  const AppColors._();

  static const bg = Color(0xFF0A0E14);
  static const bgAlt = Color(0xFF0E141C);
  static const surface = Color(0xFF151D27);
  static const surfaceHi = Color(0xFF1D2733);
  static const stroke = Color(0x1AFFFFFF);
  static const strokeStrong = Color(0x33FFFFFF);

  static const primary = Color(0xFF4C9DFF);
  static const primaryDeep = Color(0xFF2C6BE0);
  static const accent = Color(0xFF7C5CFF);

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5A5F);
  static const idle = Color(0xFF64748B);

  static const textHi = Color(0xFFF1F5F9);
  static const textMid = Color(0xFFA9B4C4);
  static const textLow = Color(0xFF6B7787);
}

class AppRadius {
  const AppRadius._();
  static const card = 24.0;
  static const tile = 20.0;
  static const chip = 999.0;
}

/// Saturn과 같은 배경 워시 — 스캐폴드 뒤에 까는 은은한 아우라 그라디언트.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? AppColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bg,
            Color.alphaBlend(accent.withValues(alpha: 0.10), AppColors.bgAlt),
            AppColors.bg,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: child,
    );
  }
}
