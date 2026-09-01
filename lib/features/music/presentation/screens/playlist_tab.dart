import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/song.dart';
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

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('Todavía no hay canciones. Agrega la primera en "Buscar".'));
        }
        // Los rechazados no se muestran en la vista general (los ven los
        // novios si acaso, pero no aporta a invitados ni a la fiesta).
        final visible = isAdmin ? songs : songs.where((s) => s.status != SongStatus.rechazada).toList();

        return ListView.builder(
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AdminControls extends ConsumerWidget {
  const _AdminControls({required this.weddingId, required this.song});
  final String weddingId;
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(musicRepositoryProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${song.votes}'),
        PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'aprobar':
                await repo.updateStatus(weddingId, song.id, SongStatus.aprobada);
              case 'rechazar':
                await repo.updateStatus(weddingId, song.id, SongStatus.rechazada);
              case 'favorita':
                await repo.setFlags(weddingId, song.id, isFavorite: !song.isFavorite);
              case 'imprescindible':
                await repo.setFlags(weddingId, song.id, isEssential: !song.isEssential);
              case 'no_reproducir':
                await repo.setFlags(weddingId, song.id, isDoNotPlay: !song.isDoNotPlay);
              case 'categoria':
                _pickCategory(context, ref);
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
      builder: (_) => SimpleDialog(
        title: const Text('Categoría'),
        children: kSuggestedCategories
            .map((c) => SimpleDialogOption(
                  onPressed: () {
                    ref.read(musicRepositoryProvider).setCategory(weddingId, song.id, c);
                    Navigator.pop(context);
                  },
                  child: Text(c),
                ))
            .toList(),
      ),
    );
  }
}
