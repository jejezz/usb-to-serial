import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/ui.dart' as xterm_ui;
import 'package:xterm2/xterm.dart';

import '../state/settings_provider.dart';
import '../state/terminal_session_provider.dart';

/// 실제 터미널 렌더링/키보드(IME 포함) 입력은 xterm2의 [xterm_ui.TerminalView]가
/// 전담한다. 한글 조합, backspace, 화살표/Ctrl 조합, ANSI 이스케이프 렌더링을
/// 전부 대신 처리해준다.
class TerminalView extends StatefulWidget {
  const TerminalView({super.key});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final _controller = xterm_ui.TerminalController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSecondaryTapDown(TapDownDetails details, Terminal terminal) async {
    final selection = _controller.selection;
    if (selection != null) {
      final text = terminal.buffer.getText(selection);
      _controller.clearSelection();
      await Clipboard.setData(ClipboardData(text: text));
    } else {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null) terminal.paste(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final settings = context.watch<SettingsProvider>();

    return xterm_ui.TerminalView(
      session.terminal,
      controller: _controller,
      autofocus: true,
      theme: settings.terminalTheme,
      textStyle: settings.terminalStyle,
      padding: const EdgeInsets.all(8),
      onSecondaryTapDown: (details, offset) => _onSecondaryTapDown(details, session.terminal),
    );
  }
}
