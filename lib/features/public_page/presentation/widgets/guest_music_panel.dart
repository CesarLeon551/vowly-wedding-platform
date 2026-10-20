import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/spotify_track.dart';
import '../../../music/application/music_providers.dart';
import '../../../music/presentation/widgets/song_tile.dart';

class GuestMusicPanel extends ConsumerStatefulWidget {
  const GuestMusicPanel({super.key, required this.weddingId, required this.uid});

  final String weddingId;
  final String uid;

  @override
  ConsumerState<GuestMusicPanel> createState() => _GuestMusicPanelState();
}

class _GuestMusicPanelState extends ConsumerState<GuestMusicPanel> {
  final _queryCtrl = TextEditingController();
  bool _searching = false;

  Future<void> _search() async {
    if (_queryCtrl.text.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await ref.read(spotifyRepositoryProvider).search(_queryCtrl.text.trim());
      if (mounted) _showResults(results);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showResults(List<SpotifyTrack> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: results.length,
          itemBuilder: (context, i) {
            final t = results[i];
            return ListTile(
              leading: t.imageUrl != null ? Image.network(t.imageUrl!, width: 44) : const Icon(Icons.music_note),
              title: Text(t.name),
              subtitle: Text(t.artist),
              trailing: TextButton(
                child: const Text('+ Agregar'),
                onPressed: () {
                  ref.read(musicRepositoryProvider).addSong(widget.weddingId, t, widget.uid);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${t.name}" agregada a la playlist')),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsStreamProvider(widget.weddingId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryCtrl,
                decoration: const InputDecoration(labelText: 'Buscar canción, artista o álbum'),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Canciones más pedidas', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        songsAsync.when(
          data: (songs) {
            final approved = songs.where((s) => s.status != SongStatus.rechazada).toList()
              ..sort((a, b) => b.votes.compareTo(a.votes));
            if (approved.isEmpty) {
              return const Text('Sé el primero en agregar una canción.');
            }
            return Column(
              children: approved
                  .take(15)
                  .map((s) => SongTile(weddingId: widget.weddingId, song: s, uid: widget.uid))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('No se pudo cargar la playlist: $e'),
        ),
      ],
    );
  }
}
