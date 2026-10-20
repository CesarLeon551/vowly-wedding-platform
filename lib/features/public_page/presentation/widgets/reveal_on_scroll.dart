import 'package:flutter/material.dart';

/// Hace que su contenido aparezca (fade + subida suave) la primera vez
/// que entra en pantalla al hacer scroll. No usa paquetes: escucha el
/// mismo ScrollController de la página y mide su posición.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.controller,
    required this.child,
    this.delayMs = 0,
  });

  final ScrollController controller;
  final Widget child;
  final int delayMs;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll> {
  bool _visible = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_visible || _scheduled || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (top >= viewportHeight * 0.92) return;

    _scheduled = true;
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
