import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'invitation_style.dart';

/// Línea - rombo - línea.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.width = 160, this.color});

  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? InvitationStyle.rose;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: c.withOpacity(0.7))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 7, height: 7, color: c),
            ),
          ),
          Expanded(child: Container(height: 1, color: c.withOpacity(0.7))),
        ],
      ),
    );
  }
}

/// Título de sección en caligrafía, con líneas a los lados y un
/// corazón debajo (como "El gran día" del diseño).
class ScriptHeading extends StatelessWidget {
  const ScriptHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final line = Expanded(
      child: Container(height: 1, color: InvitationStyle.rose.withOpacity(0.8)),
    );

    return Column(
      children: [
        Row(
          children: [
            line,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: InvitationStyle.script(isWide ? 58 : 44),
              ),
            ),
            line,
          ],
        ),
        const SizedBox(height: 4),
        const Icon(Icons.favorite_border, size: 16, color: InvitationStyle.wine),
      ],
    );
  }
}

/// Botón en píldora: relleno (acción principal) o con borde.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.filled = false,
    this.small = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool filled;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? InvitationStyle.ivory : InvitationStyle.wine;
    final padding = EdgeInsets.symmetric(horizontal: small ? 18 : 26, vertical: small ? 10 : 14);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 16 : 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(label, style: InvitationStyle.body(size: small ? 15 : 17, color: fg)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: small ? 14 : 16, color: fg),
        ],
      ],
    );

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: InvitationStyle.burgundy,
          foregroundColor: InvitationStyle.ivory,
          shape: const StadiumBorder(),
          padding: padding,
          elevation: 0,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: InvitationStyle.wine,
        side: BorderSide(color: InvitationStyle.wine.withOpacity(0.55)),
        shape: const StadiumBorder(),
        padding: padding,
      ),
      child: child,
    );
  }
}

/// Tarjeta de información corta (por ejemplo, código de vestimenta).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InvitationStyle.rose.withOpacity(0.6)),
        boxShadow: InvitationStyle.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: InvitationStyle.wine, size: 28),
          const SizedBox(height: 12),
          Text(title, style: InvitationStyle.label(), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center, style: InvitationStyle.body()),
        ],
      ),
    );
  }
}
