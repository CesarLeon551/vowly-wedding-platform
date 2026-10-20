import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/spotify_integration.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/music_providers.dart';

/// Destino del redirect_uri configurado en Spotify (vía el Worker) una
/// vez que el usuario autoriza la app. El Worker ya hizo el intercambio
/// de código + creó la playlist — aquí solo se guarda el resultado.
class SpotifyConnectedScreen extends ConsumerStatefulWidget {
  const SpotifyConnectedScreen({
    super.key,
    required this.weddingId,
    required this.refreshToken,
    required this.playlistId,
    required this.playlistUrl,
    required this.error,
  });

  final String? weddingId;
  final String? refreshToken;
  final String? playlistId;
  final String? playlistUrl;
  final String? error;

  @override
  ConsumerState<SpotifyConnectedScreen> createState() => _SpotifyConnectedScreenState();
}

class _SpotifyConnectedScreenState extends ConsumerState<SpotifyConnectedScreen> {
  bool _saving = true;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    if (widget.error != null) {
      setState(() {
        _saving = false;
        _saveError = widget.error;
      });
      return;
    }
    if (widget.weddingId == null || widget.refreshToken == null || widget.playlistId == null) {
      setState(() {
        _saving = false;
        _saveError = 'Respuesta incompleta de Spotify.';
      });
      return;
    }

    try {
      // En una pestaña recién abierta, Firebase Auth tarda un instante en
      // confirmar la sesión persistida — si seguimos de largo sin
      // esperarla, la pantalla de destino (/music) se renderiza antes de
      // que "user" exista y se queda en blanco. Esperamos el primer
      // valor real del stream de sesión antes de navegar.
      final user = await ref.read(authStateProvider.future);
      final uid = user?.uid ?? '';

      await ref.read(spotifySyncRepositoryProvider).saveIntegration(
            widget.weddingId!,
            SpotifyIntegration(
              refreshToken: widget.refreshToken!,
              playlistId: widget.playlistId!,
              playlistUrl: widget.playlistUrl ?? '',
              connectedBy: uid,
            ),
          );
      if (mounted) context.go('/w/${widget.weddingId}/music');
    } catch (e) {
      setState(() {
        _saving = false;
        _saveError = 'No se pudo guardar la conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _saving
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('No se pudo conectar con Spotify:\n$_saveError', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go(
                        widget.weddingId != null ? '/w/${widget.weddingId}/music' : '/login',
                      ),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
