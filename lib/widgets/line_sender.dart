import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/line_ending.dart';
import '../state/terminal_session_provider.dart';
import '../theme/tokens.dart';
import 'glass_card.dart';

/// 여러 줄을 미리 써두고 한 줄씩 순서대로 전송하는 스크립트 러너.
/// 그냥 Enter는 커서가 있는 줄을 전송하고, Ctrl+Enter는 평범한 줄바꿈이다.
/// 전송 후 커서는 다음 줄의 끝으로 이동해서, Enter를 반복해서 누르면
/// 위에서부터 한 줄씩 순서대로 흘러 내려가며 전송된다.
class LineSender extends StatefulWidget {
  const LineSender({super.key});

  @override
  State<LineSender> createState() => _LineSenderState();
}

class _LineSenderState extends State<LineSender> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;

    if (HardwareKeyboard.instance.isControlPressed) {
      _insertNewlineAtCursor();
    } else {
      _sendCurrentLine();
    }
    return KeyEventResult.handled;
  }

  // TextField의 "기본 동작에 맡기기"에 기대지 않고 직접 줄바꿈을 넣는다 —
  // 플랫폼 텍스트 입력 채널이 raw 키 이벤트 처리 결과와 별개로 움직여서
  // Ctrl+Enter를 그냥 무시(ignored)하면 실제로는 줄바꿈이 전혀 안 들어가는
  // 문제가 있었다 (터미널 raw 입력에서 겪은 것과 같은 종류의 이중 채널 이슈).
  void _insertNewlineAtCursor() {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, '\n');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _sendCurrentLine() {
    final session = context.read<TerminalSessionProvider>();
    if (session.status != ConnectionStatus.connected) return;

    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final safeCursor = cursor < 0 ? text.length : cursor;

    var lineStart = 0;
    if (safeCursor > 0) {
      final idx = text.lastIndexOf('\n', safeCursor - 1);
      lineStart = idx == -1 ? 0 : idx + 1;
    }
    var lineEnd = text.indexOf('\n', safeCursor);
    if (lineEnd == -1) lineEnd = text.length;

    session.send(text.substring(lineStart, lineEnd));

    if (lineEnd == text.length) {
      // 마지막 줄이었다 — 새 빈 줄을 만들고 거기로 이동해서 바로 이어 쓸 수 있게.
      final newText = '$text\n';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } else {
      var nextLineEnd = text.indexOf('\n', lineEnd + 1);
      if (nextLineEnd == -1) nextLineEnd = text.length;
      _controller.selection = TextSelection.collapsed(offset: nextLineEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TerminalSessionProvider>();
    final connected = session.status == ConnectionStatus.connected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: 84,
            child: Focus(
              onKeyEvent: _onKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: connected,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textHi),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Enter: 커서 줄 전송 · Ctrl+Enter: 줄바꿈',
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 132,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DropdownButton<LineEnding>(
                value: session.lineEnding,
                isDense: true,
                items: [
                  for (final e in LineEnding.values) DropdownMenuItem(value: e, child: Text(e.label)),
                ],
                onChanged: (value) {
                  if (value != null) session.setLineEnding(value);
                },
              ),
              Tooltip(
                message: '보낸 내용을 터미널 화면에도 표시',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Echo', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: session.localEcho,
                        activeTrackColor: AppColors.accent,
                        onChanged: (value) => session.setLocalEcho(value),
                      ),
                    ),
                  ],
                ),
              ),
              IconBadge(
                icon: Icons.send_rounded,
                color: AppColors.primary,
                active: connected,
                size: 34,
                tooltip: '현재 줄 전송',
                onTap: connected ? _sendCurrentLine : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
