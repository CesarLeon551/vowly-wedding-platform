import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/spotify_integration.dart';
import '../../application/music_providers.dart';
import '../widgets/song_tile.dart';

class PlaylistTab extends ConsumerWidget {
  const PlaylistTab({
    super.key,
    required this.weddingId,
    required this.uid,
    required this.isAdmin,
  });

  final String weddingId;
  final String uid;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsStreamProvider(weddingId));
    final integration = ref.watch(spotifyIntegrationStreamProvider(weddingId)).valueOrNull;

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('Todavía no hay canciones. Agrega la primera en "Buscar".'));
        }
        // Los rechazados no se muestran en la vista general (los ven los
        // novios si acaso, pero no aporta a invitados ni a la fiesta).
        final visible = isAdmin ? songs : songs.where((s) => s.status != SongStatus.rechazada).toList();
        final pendingSync =
            songs.where((s) => s.status == SongStatus.aprobada && !s.spotifySynced).toList();

        return Column(
          children: [
            if (isAdmin && integration != null && pendingSync.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  color: AppColors.blush.withOpacity(0.3),
                  child: ListTile(
                    leading: const Icon(Icons.sync, color: AppColors.terracotta),
                    title: Text('${pendingSync.length} canción(es) aprobadas sin sincronizar con Spotify'),
                    trailing: TextButton(
                      onPressed: () => _syncAll(ref, pendingSync, integration),
                      child: const Text('Sincronizar todo'),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final song = visible[i];
                  return SongTile(
                    weddingId: weddingId,
                    song: song,
                    uid: uid,
                    trailingAdmin: isAdmin ? _AdminControls(weddingId: weddingId, song: song) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _syncAll(WidgetRef ref, List<Song> pending, SpotifyIntegration integration) async {
    final musicRepo = ref.read(musicRepositoryProvider);
    final syncRepo = ref.read(spotifySyncRepositoryProvider);
    for (final song in pending) {
      final ok = await syncRepo.addTrackToSpotify(weddingId, integration, song.spotifyTrackId);
      if (ok) await musicRepo.setSpotifySynced(weddingId, song.id, true);
    }
  }
}

class _AdminControls extends ConsumerWidget {
  const _AdminControls({required this.weddingId, required this.song});
  final String weddingId;
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(musicRepositoryProvider);
    final syncRepo = ref.read(spotifySyncRepositoryProvider);
    final integration = ref.watch(spotifyIntegrationStreamProvider(weddingId)).valueOrNull;

    Future<void> syncIfConnected({required bool shouldBeInPlaylist}) async {
      if (integration == null) return;
      final ok = shouldBeInPlaylist
          ? await syncRepo.addTrackToSpotify(weddingId, integration, song.spotifyTrackId)
          : await syncRepo.removeTrackFromSpotify(weddingId, integration, song.spotifyTrackId);
      // Mejor esfuerzo: si falla (ver nota de Fase 7 sobre 403 intermitentes
      // de Spotify en modo desarrollo), el estado interno de la app sigue
      // siendo correcto — solo no se refleja en Spotify por ahora. El
      // usuario puede reintentar con "Sincronizar ahora" más adelante.
      if (ok) await repo.setSpotifySynced(weddingId, song.id, shouldBeInPlaylist);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${song.votes}'),
        if (integration != null && song.status == SongStatus.aprobada && !song.spotifySynced)
          const Tooltip(
            message: 'Aprobada pero no se pudo sincronizar con Spotify — reintenta desde el menú.',
            child: Icon(Icons.sync_problem, color: AppColors.gold, size: 18),
          ),
        PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'aprobar':
                await repo.updateStatus(weddingId, song.id, SongStatus.aprobada);
                await syncIfConnected(shouldBeInPlaylist: true);
              case 'rechazar':
                await repo.updateStatus(weddingId, song.id, SongStatus.rechazada);
                await syncIfConnected(shouldBeInPlaylist: false);
              case 'favorita':
                await repo.setFlags(weddingId, song.id, isFavorite: !song.isFavorite);
              case 'imprescindible':
                await repo.setFlags(weddingId, song.id, isEssential: !song.isEssential);
              case 'no_reproducir':
                await repo.setFlags(weddingId, song.id, isDoNotPlay: !song.isDoNotPlay);
              case 'categoria':
                _pickCategory(context, ref);
              case 'reintentar_spotify':
                await syncIfConnected(shouldBeInPlaylist: song.status == SongStatus.aprobada);
              case 'eliminar':
                await repo.deleteSong(weddingId, song.id);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'aprobar',
              child: Text(song.status == SongStatus.aprobada ? '✓ Aprobada' : 'Aprobar'),
            ),
            const PopupMenuItem(value: 'rechazar', child: Text('Rechazar')),
            PopupMenuItem(
              value: 'favorita',
              child: Text(song.isFavorite ? '★ Quitar favorita' : 'Marcar favorita'),
            ),
            PopupMenuItem(
              value: 'imprescindible',
              child: Text(song.isEssential ? '✓ Quitar imprescindible' : 'Marcar imprescindible'),
            ),
            PopupMenuItem(
              value: 'no_reproducir',
              child: Text(song.isDoNotPlay ? '✓ Permitir de nuevo' : 'Marcar "NO reproducir"'),
            ),
            const PopupMenuItem(value: 'categoria', child: Text('Asignar categoría')),
            if (integration != null)
              const PopupMenuItem(value: 'reintentar_spotify', child: Text('Reintentar sincronizar')),
            const PopupMenuItem(
                value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: AppColors.danger))),
          ],
        ),
      ],
    );
  }

  void _pickCategory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Categoría'),
        children: kSuggestedCategories
            .map((c) => SimpleDialogOption(
                  onPressed: () {
                    ref.read(musicRepositoryProvider).setCategory(weddingId, song.id, c);
                    Navigator.pop(dialogContext);
                  },
                  child: Text(c),
                ))
            .toList(),
      ),
    );
  }
}
