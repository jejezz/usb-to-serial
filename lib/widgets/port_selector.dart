import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/serial_service.dart';
import '../theme/tokens.dart';
import 'glass_card.dart';

/// 시리얼 포트 드롭다운 + 새로고침.
/// 연결돼 있지 않을 때는 2초마다 자동으로 포트 목록을 다시 조회해서
/// 핫플러그(뽑았다 꽂았다)를 반영한다.
class PortSelector extends StatefulWidget {
  const PortSelector({
    super.key,
    required this.selectedPort,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedPort;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  State<PortSelector> createState() => _PortSelectorState();
}

class _PortSelectorState extends State<PortSelector> {
  List<String> _ports = SerialService.availablePorts();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _displayName(String portPath) => portPath.startsWith('/dev/') ? portPath.substring(5) : portPath;

  void _refresh() {
    final ports = SerialService.availablePorts();
    if (listEquals(ports, _ports)) return;
    setState(() => _ports = ports);
    if (widget.selectedPort != null && !ports.contains(widget.selectedPort)) {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _ports.contains(widget.selectedPort) ? widget.selectedPort : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              hintText: '포트',
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.usb_rounded, size: 18, color: AppColors.accent),
              prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 16),
            ),
            items: [
              for (final p in _ports)
                DropdownMenuItem(
                  value: p,
                  // macOS 포트는 죄다 "/dev/"로 시작해서, 좁은 폭에서는 그
                  // 공통 접두사만 보이고 정작 구분되는 부분(뒷부분)이 안
                  // 보이는 문제가 있었다 — 표시할 때만 걷어낸다.
                  child: Tooltip(
                    message: p,
                    child: Text(_displayName(p), overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
            onChanged: widget.enabled ? widget.onChanged : null,
          ),
        ),
        IconBadge(
          icon: Icons.refresh_rounded,
          color: AppColors.idle,
          size: 34,
          tooltip: '포트 새로고침',
          onTap: widget.enabled ? _refresh : null,
        ),
      ],
    );
  }
}
