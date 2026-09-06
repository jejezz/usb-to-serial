import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_terminal_theme.dart';
import '../state/settings_provider.dart';
import '../theme/tokens.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  InputDecoration _insetDecoration({required String label, String? helper, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_rounded, size: 24, color: AppColors.primary),
          SizedBox(width: 10),
          Text('터미널 설정'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: settings.fontFamily,
              decoration: _insetDecoration(label: '폰트'),
              items: [
                for (final f in kFontFamilies) DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontFamily: f))),
              ],
              onChanged: (value) {
                if (value != null) settings.setFontFamily(value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('크기', style: TextStyle(color: AppColors.textMid)),
                Expanded(
                  child: Slider(
                    value: settings.fontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    activeColor: AppColors.primary,
                    label: settings.fontSize.toStringAsFixed(0),
                    onChanged: settings.setFontSize,
                  ),
                ),
                SizedBox(width: 24, child: Text(settings.fontSize.toStringAsFixed(0))),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppTerminalTheme>(
              initialValue: settings.appTheme,
              decoration: _insetDecoration(
                label: '테마',
                prefixIcon: const Icon(Icons.palette_rounded, size: 20, color: AppColors.accent),
              ),
              items: [
                for (final t in AppTerminalTheme.values) DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (value) {
                if (value != null) settings.setAppTheme(value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: settings.scrollbackLines,
              decoration: _insetDecoration(label: '스크롤백 줄 수', helper: '바꾸면 현재 화면 내용은 지워집니다'),
              items: [
                for (final n in kScrollbackLinesOptions) DropdownMenuItem(value: n, child: Text('$n줄')),
              ],
              onChanged: (value) {
                if (value != null) settings.setScrollbackLines(value);
              },
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
