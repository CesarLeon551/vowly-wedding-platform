import 'package:flutter/material.dart';

/// Revela un texto en caligrafía de izquierda a derecha, como si se
/// escribiera a mano. No separa el texto en letras: las tipografías
/// script dependen de que las letras se conecten, y partirlas en
/// widgets individuales rompe esa unión.
class ScriptReveal extends StatefulWidget {
  const ScriptReveal({
    super.key,
    required this.text,
    required this.style,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1600),
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final Duration delay;
  final Duration duration;
  final TextAlign textAlign;

  @override
  State<ScriptReveal> createState() => _ScriptRevealState();
}

class _ScriptRevealState extends State<ScriptReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _progress =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => ClipRect(
        clipper: _RevealClipper(_progress.value),
        child: Opacity(opacity: (_progress.value * 4).clamp(0.0, 1.0), child: child),
      ),
      child: Text(widget.text, style: widget.style, textAlign: widget.textAlign),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.progress);

  final double progress;

  // El rectángulo se extiende en vertical: los rasgos de la caligrafía
  // (ascendentes y descendentes) sobresalen de la caja del texto.
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width * 0.05, -size.height, size.width * progress, size.height * 2);

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) => oldClipper.progress != progress;
}
