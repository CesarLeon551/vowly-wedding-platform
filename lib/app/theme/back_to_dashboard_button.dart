import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Todas las pantallas de módulo (Presupuesto, Ahorro, Invitados, Música,
/// etc.) se navegan con context.go() desde el Dashboard, que REEMPLAZA la
/// ruta en vez de apilarla — por eso Flutter nunca agrega el botón de
/// regreso automático. Este widget lo agrega explícitamente.
class BackToDashboardButton extends StatelessWidget {
  const BackToDashboardButton({super.key, required this.weddingId});
  final String weddingId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Volver al dashboard',
      onPressed: () => context.go('/w/$weddingId/dashboard'),
    );
  }
}
