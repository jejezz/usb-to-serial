import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/sessions_provider.dart';
import '../state/terminal_session_provider.dart';

/// 세션(탭) 목록을 보여주는 얇은 가로 바. 탭이 동적으로 추가/삭제돼서
/// Material `TabBar`/`TabController`(길이 변경 시 재생성이 번거로움) 대신
/// 직접 만들었다.
class TabBarRow extends StatelessWidget {
  const TabBarRow({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = context.watch<SessionsProvider>();
    final sessions = sessionsProvider.sessions;
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 34,
      color: colors.surfaceContainer,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _TabChip(
                  session: sessions[index],
                  isActive: index == sessionsProvider.activeIndex,
                  canClose: sessions.length > 1,
                  onTap: () => sessionsProvider.setActive(index),
                  onClose: () => sessionsProvider.closeSession(index),
                );
              },
            ),
          ),
          IconButton(
            tooltip: '새 탭 (⌘T)',
            visualDensity: VisualDensity.compact,
            onPressed: sessionsProvider.addSession,
            icon: Icon(Icons.add_sharp, size: 20, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.session,
    required this.isActive,
    required this.canClose,
    required this.onTap,
    required this.onClose,
  });

  final TerminalSessionProvider session;
  final bool isActive;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // 이 탭 하나의 제목/연결 상태가 바뀔 때만 다시 그리면 되니, 탭바
    // 전체가 아니라 여기서 해당 session만 직접 listen한다.
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final Color dotColor = switch (session.status) {
          ConnectionStatus.connected => Colors.greenAccent,
          ConnectionStatus.error => Colors.redAccent,
          ConnectionStatus.disconnected => colors.outline,
        };

        return InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 190),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isActive ? colors.surfaceContainerHigh : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: isActive ? colors.primary : Colors.transparent, width: 2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: dotColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(session.tabTitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ),
                if (canClose) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close_sharp, size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
