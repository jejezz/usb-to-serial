import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Saturn(lib/ui/widgets/glass_card.dart)과 같은 표면 — 반투명 패널 +
/// 헤어라인 보더, active일 때는 톤 워시 그라디언트 + 글로우.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
    this.active = false,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final bool active;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.primary;
    const base = AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [
                  Color.alphaBlend(tint.withValues(alpha: 0.26), base),
                  Color.alphaBlend(tint.withValues(alpha: 0.08), base),
                ]
              : [base, Color.alphaBlend(Colors.white.withValues(alpha: 0.02), base)],
        ),
        border: Border.all(
          color: active ? tint.withValues(alpha: 0.55) : AppColors.stroke,
          width: 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: tint.withValues(alpha: 0.24),
                  blurRadius: 26,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Saturn의 IconBadge 그대로 — 둥근 사각형 아이콘 배지.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.active = false,
    this.size = 40,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final bool active;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: active ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.14),
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: active ? Colors.black.withValues(alpha: 0.85) : color,
      ),
    );
    if (onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(size * 0.32), onTap: onTap, child: badge),
      );
    }
    if (tooltip != null) badge = Tooltip(message: tooltip!, child: badge);
    return badge;
  }
}

/// Saturn의 StatusPill 그대로 — 연결 상태/기록 상태 배지.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: color)
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
