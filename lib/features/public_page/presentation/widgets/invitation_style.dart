import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens visuales de la invitación pública (diseño vino + marfil con
/// títulos en script). Viven aquí y no en AppTheme porque solo aplican
/// a la experiencia del invitado, no al panel de administración.
class InvitationStyle {
  InvitationStyle._();

  // Paleta
  static const burgundy = Color(0xFF4A1523); // botones, nombres
  static const burgundyDark = Color(0xFF2E0C16); // barra de navegación
  static const wine = Color(0xFF6B2737); // títulos y acentos
  static const ivory = Color(0xFFF8F2EC); // fondo principal
  static const blush = Color(0xFFF1E3DF); // fondo alterno de secciones
  static const rose = Color(0xFFC9A3A0); // bordes y detalles suaves
  static const ink = Color(0xFF3A2A2E); // texto corrido

  static const maxContentWidth = 1040.0;
  static const navHeight = 60.0;

  /// Caligrafía para títulos y nombres. Legible desde ~28 px.
  static TextStyle script(double size, {Color? color}) => GoogleFonts.greatVibes(
        fontSize: size,
        color: color ?? wine,
        height: 1.15,
      );

  /// Serif para fechas, nombres de lugares y cifras.
  static TextStyle display(
    double size, {
    Color? color,
    FontStyle? fontStyle,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        fontStyle: fontStyle,
        height: 1.15,
        color: color ?? burgundy,
        fontFeatures: const [FontFeature.liningFigures()],
      );

  /// Etiquetas pequeñas en mayúsculas con tracking amplio.
  static TextStyle label({Color? color, double size = 12, double spacing = 3.2}) =>
      GoogleFonts.jost(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: spacing,
        color: color ?? wine,
      );

  /// Texto corrido: serif en cursiva, como el mockup.
  static TextStyle body({Color? color, double size = 17, FontStyle fontStyle = FontStyle.italic}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontStyle: fontStyle,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: color ?? ink.withOpacity(0.85),
      );

  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: burgundy.withOpacity(0.08),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}
