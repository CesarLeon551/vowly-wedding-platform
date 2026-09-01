import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/song.dart';
import '../../application/music_providers.dart';
import '../widgets/song_tile.dart';

class RankingTab extends ConsumerWidget {
  const RankingTab({super.key, required this.weddingId, required this.uid});
  final String weddingId;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsStreamProvider(weddingId));

    return songsAsync.when(
      data: (songs) {
        final approved = songs.where((s) => s.status != SongStatus.rechazada).toList();
        final mostVoted = [...approved]..sort((a, b) => b.votes.compareTo(a.votes));
        final favorites = approved.where((s) => s.isFavorite).toList();
        final latest = [...approved]..sort((a, b) => b.addedAt.compareTo(a.addedAt));

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _section(context, '🔥 Más pedidas', mostVoted.take(10)),
            _section(context, '★ Favoritas de los novios', favorites),
            _section(context, '🆕 Últimas agregadas', latest.take(10)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _section(BuildContext context, String title, Iterable<Song> songs) {
    if (songs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...songs.map((s) => SongTile(weddingId: weddingId, song: s, uid: uid)),
        const SizedBox(height: 16),
      ],
    );
  }
}
