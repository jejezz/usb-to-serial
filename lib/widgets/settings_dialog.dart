import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_terminal_theme.dart';
import '../state/settings_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_sharp, size: 24, color: accent),
          const SizedBox(width: 10),
          const Text('터미널 설정'),
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
              decoration: const InputDecoration(labelText: '폰트'),
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
                const Text('크기'),
                Expanded(
                  child: Slider(
                    value: settings.fontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
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
              decoration: InputDecoration(
                labelText: '테마',
                prefixIcon: Icon(Icons.palette_sharp, size: 20, color: accent),
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
              decoration: const InputDecoration(
                labelText: '스크롤백 줄 수',
                helperText: '바꾸면 현재 화면 내용은 지워집니다',
              ),
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
