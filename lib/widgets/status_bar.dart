import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/terminal_session_provider.dart';

/// 바이트 카운트, 로깅 상태/제어, 전체 복사를 한 줄로 모아둔 상태 바.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final theme = Theme.of(context);
    final connected = session.status == ConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              session.isLogging
                  ? '${session.byteCount} bytes  ·  ● 기록 중: ${session.logFilePath?.split('/').last ?? ''}'
                  : '${session.byteCount} bytes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: session.isLogging ? Colors.redAccent : null,
                fontWeight: session.isLogging ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: session.isLogging ? '기록 정지 (⌘⇧R)' : '기록 시작 (⌘⇧R)',
            onPressed: (connected || session.isLogging) ? () => session.toggleLogging() : null,
            icon: Icon(
              session.isLogging ? Icons.stop_circle_sharp : Icons.fiber_manual_record_sharp,
              size: 22,
              color: session.isLogging ? theme.colorScheme.primary : Colors.redAccent,
            ),
          ),
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: session.displayText)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('전체 복사'),
          ),
        ],
      ),
    );
  }
}
