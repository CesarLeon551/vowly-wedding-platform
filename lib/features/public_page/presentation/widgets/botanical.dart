import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rama con hojas dibujada en línea fina (sin imágenes), como las del
/// diseño. [flipX] la refleja para usarla del lado contrario.
class LeafBranch extends StatelessWidget {
  const LeafBranch({
    super.key,
    required this.color,
    this.width = 110,
    this.height = 190,
    this.flipX = false,
    this.leaves = 6,
    this.opacity = 0.55,
  });

  final Color color;
  final double width;
  final double height;
  final bool flipX;
  final int leaves;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flipX ? -1 : 1, 1, 1),
        child: CustomPaint(
          size: Size(width, height),
          painter: _LeafBranchPainter(color, opacity, leaves),
        ),
      ),
    );
  }
}

class _LeafBranchPainter extends CustomPainter {
  _LeafBranchPainter(this.color, this.opacity, this.leaves);

  final Color color;
  final double opacity;
  final int leaves;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final vein = Paint()
      ..color = color.withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final stem = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.45, size.width * 0.75, 0);
    canvas.drawPath(stem, stroke);

    final metric = stem.computeMetrics().first;
    for (var i = 1; i <= leaves; i++) {
      final tangent = metric.getTangentForOffset(metric.length * (i / (leaves + 1)));
      if (tangent == null) continue;

      final direction = math.atan2(tangent.vector.dy, tangent.vector.dx);
      final side = i.isEven ? 1.0 : -1.0;
      final len = size.shortestSide * (0.34 - 0.03 * i).clamp(0.12, 0.34);

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(direction + side * 0.85);

      final leaf = Path()
        ..quadraticBezierTo(len * 0.5, -len * 0.32, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.32, 0, 0);
      canvas.drawPath(leaf, stroke);
      canvas.drawLine(Offset.zero, Offset(len * 0.92, 0), vein);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafBranchPainter old) =>
      old.color != color || old.opacity != opacity || old.leaves != leaves;
}

/// Ola rellena de [color]. Con [flip] la ola cuelga desde arriba.
class WaveEdge extends StatelessWidget {
  const WaveEdge({super.key, required this.color, this.height = 48, this.flip = false});

  final Color color;
  final double height;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter(color, flip)),
    );
  }
}

/// Transición ondulada entre dos secciones de color plano: arriba se ve
/// [from], y la ola rellena con [to] da paso a la siguiente sección.
class SectionWave extends StatelessWidget {
  const SectionWave({super.key, required this.from, required this.to, this.height = 44});

  final Color from;
  final Color to;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(color: from, child: WaveEdge(color: to, height: height));
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.color, this.flip);

  final Color color;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    if (flip) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..cubicTo(w * 0.18, h * 0.05, w * 0.32, h * 1.0, w * 0.5, h * 0.5)
      ..cubicTo(w * 0.68, 0, w * 0.84, h * 0.9, w, h * 0.35)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.color != color || old.flip != flip;
}
