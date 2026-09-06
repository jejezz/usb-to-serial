import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_provider.dart';
import '../state/terminal_session_provider.dart';
import '../utils/hex_dump.dart';

/// 실제로 수신한 raw 바이트([TerminalSessionProvider.rawBytes])를 hex dump로
/// 보여주는 읽기 전용 뷰. 터미널 화면(xterm2)과 달리 로컬 에코나 키 입력을
/// 반영하지 않는다 — 오직 "진짜로 들어온 바이트"만 보여준다. 폰트/테마는
/// 터미널 화면과 같은 설정([SettingsProvider])을 따른다.
class HexView extends StatefulWidget {
  const HexView({super.key});

  @override
  State<HexView> createState() => _HexViewState();
}

class _HexViewState extends State<HexView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = settings.terminalTheme;
    _scrollToBottom();

    return Container(
      width: double.infinity,
      color: theme.background,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          hexDump(session.rawBytes),
          style: TextStyle(
            color: theme.foreground,
            fontFamily: settings.fontFamily,
            fontSize: settings.fontSize * 0.85,
          ),
        ),
      ),
    );
  }
}
