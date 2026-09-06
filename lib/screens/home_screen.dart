import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_settings.dart';
import '../state/sessions_provider.dart';
import '../state/terminal_session_provider.dart';
import '../widgets/baud_rate_selector.dart';
import '../widgets/hex_view.dart';
import '../widgets/line_sender.dart';
import '../widgets/port_selector.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/status_bar.dart';
import '../widgets/tab_bar_row.dart';
import '../widgets/terminal_view.dart';

/// 탭바 + 활성 탭의 세션 화면. 탭별 상태([TerminalSessionProvider])는
/// [SessionsProvider]가 들고 있고, 여기서는 활성 세션 하나를 골라
/// 아래로 스코프해서 내려준다 — 그 아래(PortSelector 등)는 원래 단일
/// 세션 시절 코드 그대로 재사용된다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = context.watch<SessionsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TabBarRow(),
            Expanded(
              child: ChangeNotifierProvider<TerminalSessionProvider>.value(
                value: sessionsProvider.active,
                child: const _SessionBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody();

  void _connect(TerminalSessionProvider session) {
    final port = session.pendingPort;
    final baud = session.pendingBaudRate;
    if (port == null || baud == null) return;
    session.connect(ConnectionSettings(portName: port, baudRate: baud));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final connected = session.status == ConnectionStatus.connected;
    final canConnect = !connected && session.pendingPort != null && session.pendingBaudRate != null;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 상단 툴바: 연결 컨트롤 + 뷰 전환 + 설정을 전부 한 줄에 압축.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(Icons.cable_sharp, size: 22, color: colors.primary),
              const SizedBox(width: 8),
              SizedBox(
                width: 230,
                child: PortSelector(
                  selectedPort: session.pendingPort,
                  enabled: !connected,
                  onChanged: session.setPendingPort,
                ),
              ),
              const SizedBox(width: 4),
              BaudRateSelector(
                initialBaudRate: session.pendingBaudRate ?? 115200,
                enabled: !connected,
                onChanged: session.setPendingBaudRate,
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: connected ? session.disconnect : (canConnect ? () => _connect(session) : null),
                child: Text(connected ? 'Disconnect' : 'Connect'),
              ),
              const SizedBox(width: 12),
              SegmentedButton<ViewMode>(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  const ButtonSegment(
                    value: ViewMode.terminal,
                    tooltip: 'Terminal',
                    icon: Icon(Icons.terminal_sharp, size: 18),
                  ),
                  const ButtonSegment(
                    value: ViewMode.hex,
                    tooltip: 'Hex',
                    icon: Icon(Icons.data_array_sharp, size: 18),
                  ),
                ],
                selected: {session.viewMode},
                onSelectionChanged: (selection) => session.setViewMode(selection.first),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '폰트 / 테마',
                onPressed: () => showDialog<void>(context: context, builder: (_) => const SettingsDialog()),
                icon: Icon(Icons.settings_sharp, size: 22, color: colors.primary),
              ),
            ],
          ),
        ),
        if (session.status == ConnectionStatus.error)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: colors.errorContainer,
            child: Row(
              children: [
                Icon(Icons.error_sharp, size: 20, color: colors.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.errorMessage ?? '알 수 없는 오류',
                    style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: session.viewMode == ViewMode.terminal ? const TerminalView() : const HexView(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBar(),
              const SizedBox(height: 6),
              const LineSender(),
            ],
          ),
        ),
      ],
    );
  }
}
