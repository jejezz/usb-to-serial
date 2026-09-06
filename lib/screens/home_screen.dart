import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_settings.dart';
import '../state/sessions_provider.dart';
import '../state/terminal_session_provider.dart';
import '../theme/tokens.dart';
import '../widgets/baud_rate_selector.dart';
import '../widgets/glass_card.dart';
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

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 상단 툴바: 연결 컨트롤 + 뷰 전환 + 설정을 전부 한 줄에 압축.
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IconBadge(icon: Icons.cable_rounded, color: AppColors.accent, size: 32),
                const SizedBox(width: 8),
                SizedBox(
                  width: 210,
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
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: connected ? session.disconnect : (canConnect ? () => _connect(session) : null),
                  child: Text(connected ? 'Disconnect' : 'Connect'),
                ),
                const SizedBox(width: 8),
                SegmentedButton<ViewMode>(
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(
                      value: ViewMode.terminal,
                      tooltip: 'Terminal',
                      icon: Icon(Icons.terminal_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: ViewMode.hex,
                      tooltip: 'Hex',
                      icon: Icon(Icons.grid_view_rounded, size: 18),
                    ),
                  ],
                  selected: {session.viewMode},
                  onSelectionChanged: (selection) => session.setViewMode(selection.first),
                ),
                const Spacer(),
                IconBadge(
                  icon: Icons.settings_rounded,
                  color: AppColors.idle,
                  size: 32,
                  tooltip: '폰트 / 테마',
                  onTap: () => showDialog<void>(context: context, builder: (_) => const SettingsDialog()),
                ),
              ],
            ),
          ),
          if (session.status == ConnectionStatus.error) ...[
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              accent: AppColors.danger,
              active: true,
              child: Row(
                children: [
                  const Icon(Icons.error_rounded, size: 20, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.errorMessage ?? '알 수 없는 오류',
                      style: const TextStyle(color: AppColors.textHi, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(10),
              accent: switch (session.status) {
                ConnectionStatus.connected => AppColors.success,
                ConnectionStatus.error => AppColors.danger,
                ConnectionStatus.disconnected => null,
              },
              active: session.status == ConnectionStatus.connected,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    child: session.viewMode == ViewMode.terminal ? const TerminalView() : const HexView(),
                  ),
                  if (connected)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: StatusPill(label: 'CONNECTED', color: AppColors.success),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: const StatusBar()),
          const SizedBox(height: 10),
          GlassCard(padding: const EdgeInsets.all(12), child: const LineSender()),
        ],
      ),
    );
  }
}
