import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/sessions_provider.dart';
import '../state/terminal_session_provider.dart';
import '../theme/tokens.dart';
import 'glass_card.dart';

/// 세션(탭) 목록을 보여주는 얇은 가로 바. 탭이 동적으로 추가/삭제돼서
/// Material `TabBar`/`TabController`(길이 변경 시 재생성이 번거로움) 대신
/// 직접 만들었다. Saturn처럼 하단 고정 탭 대신, 세션을 전환한다는 성격에
/// 맞게 상단에 필(pill) 모양 GlassCard로 배치했다.
class TabBarRow extends StatelessWidget {
  const TabBarRow({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = context.watch<SessionsProvider>();
    final sessions = sessionsProvider.sessions;

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
          const SizedBox(width: 8),
          IconBadge(
            icon: Icons.add_rounded,
            color: AppColors.primary,
            tooltip: '새 탭 (⌘T)',
            onTap: sessionsProvider.addSession,
          ),
          const SizedBox(width: 12),
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
    // 이 탭 하나의 제목/연결 상태가 바뀔 때만 다시 그리면 되니, 탭바
    // 전체가 아니라 여기서 해당 session만 직접 listen한다.
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final Color statusColor = switch (session.status) {
          ConnectionStatus.connected => AppColors.success,
          ConnectionStatus.error => AppColors.danger,
          ConnectionStatus.disconnected => AppColors.idle,
        };

        return GestureDetector(
          onTap: onTap,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            radius: AppRadius.chip,
            accent: statusColor,
            active: isActive,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 90, maxWidth: 190),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      session.tabTitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppColors.textHi : AppColors.textMid,
                      ),
                    ),
                  ),
                  if (canClose) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, size: 14, color: AppColors.textLow),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
