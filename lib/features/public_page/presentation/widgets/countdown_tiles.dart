import 'dart:async';

import 'package:flutter/material.dart';

import 'invitation_style.dart';

/// Cuenta regresiva en vivo (días, horas, minutos, segundos).
class CountdownTiles extends StatefulWidget {
  const CountdownTiles({super.key, required this.target});

  final DateTime target;

  @override
  State<CountdownTiles> createState() => _CountdownTilesState();
}

class _CountdownTilesState extends State<CountdownTiles> {
  Timer? _timer;
  late Duration _remaining = _calc();

  Duration _calc() {
    final diff = widget.target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calc());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.target.isAfter(DateTime.now())) {
      return Text('¡Ya celebramos!', style: InvitationStyle.script(46));
    }

    String two(int n) => n.toString().padLeft(2, '0');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Row(
        children: [
          Expanded(child: _Tile(value: '${_remaining.inDays}', label: 'DÍAS')),
          const SizedBox(width: 10),
          Expanded(child: _Tile(value: two(_remaining.inHours % 24), label: 'HORAS')),
          const SizedBox(width: 10),
          Expanded(child: _Tile(value: two(_remaining.inMinutes % 60), label: 'MIN')),
          const SizedBox(width: 10),
          Expanded(child: _Tile(value: two(_remaining.inSeconds % 60), label: 'SEG')),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InvitationStyle.rose.withOpacity(0.6)),
        boxShadow: InvitationStyle.softShadow,
      ),
      child: Column(
        children: [
          Text(value, style: InvitationStyle.display(38, color: InvitationStyle.wine)),
          const SizedBox(height: 4),
          Text(label, style: InvitationStyle.label(size: 10, spacing: 1.8)),
        ],
      ),
    );
  }
}
