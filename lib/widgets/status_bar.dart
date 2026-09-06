import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/terminal_session_provider.dart';
import '../theme/tokens.dart';
import 'glass_card.dart';

/// 바이트 카운트, 로깅 상태/제어, 전체 복사를 한 줄로 모아둔 상태 바.
/// (배경/여백은 이 위젯을 감싸는 [GlassCard] 몫 — 여긴 내용만.)
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final connected = session.status == ConnectionStatus.connected;

    return Row(
      children: [
        Text(
          '${session.byteCount} bytes',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMid, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 10),
        if (session.isLogging)
          StatusPill(
            label: '기록 중 · ${session.logFilePath?.split('/').last ?? ''}',
            color: AppColors.danger,
          ),
        const Spacer(),
        IconBadge(
          icon: session.isLogging ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
          color: session.isLogging ? AppColors.primary : AppColors.danger,
          active: session.isLogging,
          tooltip: session.isLogging ? '기록 정지 (⌘⇧R)' : '기록 시작 (⌘⇧R)',
          onTap: (connected || session.isLogging) ? () => session.toggleLogging() : null,
        ),
        const SizedBox(width: 6),
        IconBadge(
          icon: Icons.content_copy_rounded,
          color: AppColors.idle,
          tooltip: '전체 복사',
          onTap: () => Clipboard.setData(ClipboardData(text: session.displayText)),
        ),
      ],
    );
  }
}
