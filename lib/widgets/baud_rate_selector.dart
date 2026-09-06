import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'glass_card.dart';

const kCommonBaudRates = <int>[1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400];

/// 보드레이트 입력 필드 + 흔한 값 프리셋 메뉴.
/// 텍스트 필드가 유일한 소스이고, 프리셋은 그 값을 채워줄 뿐이다.
/// 유효하지 않은 값이면 [onChanged]에 null을 넘겨 상위(Connect 버튼)가 막게 한다.
class BaudRateSelector extends StatefulWidget {
  const BaudRateSelector({
    super.key,
    required this.initialBaudRate,
    required this.enabled,
    required this.onChanged,
  });

  final int initialBaudRate;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  State<BaudRateSelector> createState() => _BaudRateSelectorState();
}

class _BaudRateSelectorState extends State<BaudRateSelector> {
  late final _controller = TextEditingController(text: '${widget.initialBaudRate}');
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final value = int.tryParse(text.trim());
    final valid = value != null && value > 0;
    setState(() => _errorText = valid ? null : '양의 정수를 입력하세요');
    widget.onChanged(valid ? value : null);
  }

  void _pickPreset(int baud) {
    _controller.text = '$baud';
    _onTextChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Baud',
              errorText: _errorText,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onTextChanged,
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<int>(
          enabled: widget.enabled,
          tooltip: '흔한 보드레이트',
          icon: const IconBadge(icon: Icons.speed_rounded, color: AppColors.accent, size: 34),
          onSelected: _pickPreset,
          itemBuilder: (context) => [
            for (final b in kCommonBaudRates) PopupMenuItem(value: b, child: Text('$b')),
          ],
        ),
      ],
    );
  }
}
