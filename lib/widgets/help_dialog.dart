import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 기능 사용법 요약 도움말.
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  static const _sections = <(String, String)>[
    ('연결하기', '포트를 고르고 보드레이트를 설정한 뒤 Connect. 포트 목록은 2초마다 자동으로 새로고침돼서 핫플러그도 반영된다. 연결되면 프롬프트를 깨우려고 Enter를 한 번 자동으로 보낸다.'),
    ('탭', '+ 버튼으로 새 세션(탭)을 열어 여러 포트에 동시 접속할 수 있다. 백그라운드 탭도 계속 데이터를 받고 로깅한다. 탭 하나는 항상 남아 있어야 해서 마지막 탭은 닫을 수 없다.'),
    ('터미널에 직접 타이핑', '터미널 화면을 클릭해 포커스를 준 뒤 바로 입력할 수 있다. 화살표/Ctrl 조합/백스페이스가 다 지원된다 (단, 한글 조합은 라이브러리 한계로 깨진다).'),
    ('Line Sender', '여러 줄을 미리 써두고 Enter로 커서가 있는 줄만 전송한다. Ctrl+Enter는 그냥 줄바꿈. 보낸 뒤 커서는 다음 줄 끝으로 이동해서, Enter를 반복하면 위에서부터 순서대로 흘러간다.'),
    ('Hex View', '툴바의 Terminal/Hex 토글로 전환. 실제로 수신한 바이트 그대로를 hex dump로 보여준다.'),
    ('로깅', '● 버튼(또는 ⌘⇧R)으로 시작하면 저장 위치/파일명을 직접 고르는 대화상자가 뜬다. 여러 탭이 동시에 각자 로깅할 수 있다.'),
    ('폰트 / 테마', '설정(⚙) 다이얼로그에서 폰트/크기/색상 테마(Solarized, Dracula, Nord, Gruvbox 등)와 스크롤백 줄 수를 바꿀 수 있다. 재실행해도 유지된다.'),
  ];

  static const _shortcuts = <(String, String)>[
    ('⌘T', '새 탭'),
    ('⌘W', '현재 탭 닫기'),
    ('⌘⇧R', '로깅 시작/정지'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 22, color: AppColors.primary),
          SizedBox(width: 10),
          Text('도움말'),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (title, body) in _sections) ...[
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textHi)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textMid)),
                const SizedBox(height: 16),
              ],
              const Text('단축키', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textHi)),
              const SizedBox(height: 8),
              for (final (key, desc) in _shortcuts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(key, style: const TextStyle(fontSize: 12, color: AppColors.textHi)),
                      ),
                      const SizedBox(width: 10),
                      Text(desc, style: const TextStyle(fontSize: 12.5, color: AppColors.textMid)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
      ],
    );
  }
}
