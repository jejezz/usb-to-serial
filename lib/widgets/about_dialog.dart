import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 앱 이름/버전/설명을 보여주는 정보 다이얼로그.
class PortsideAboutDialog extends StatelessWidget {
  const PortsideAboutDialog({super.key});

  static const version = '0.1.1';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cable_rounded, size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            const Text('Portside', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textHi)),
            const SizedBox(height: 4),
            Text('버전 $version', style: const TextStyle(fontSize: 12.5, color: AppColors.textMid)),
            const SizedBox(height: 16),
            const Text(
              'macOS 전용 USB-to-Serial(COM) 터미널.\nCoolTerm은 오래됐고 Termius는 유료라서 직접 만들었다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMid),
            ),
            const SizedBox(height: 16),
            const Text(
              'github.com/jejezz/usb-to-serial',
              style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
      ],
    );
  }
}
