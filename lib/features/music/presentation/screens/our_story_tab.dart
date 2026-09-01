import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/spotify_track.dart';
import '../../application/music_providers.dart';

class OurStoryTab extends ConsumerWidget {
  const OurStoryTab({super.key, required this.weddingId, required this.uid, required this.isCouple});

  final String weddingId;
  final String uid;
  final bool isCouple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isCouple) {
      return const Center(child: Text('"Nuestra historia" es privada — solo los novios pueden verla.'));
    }

    final storyAsync = ref.watch(ourStoryStreamProvider(weddingId));

    return Scaffold(
      body: storyAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('Guarda las canciones que tengan un significado especial para ustedes.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: songs.length,
            itemBuilder: (context, i) {
              final s = songs[i];
              return Card(
                child: ListTile(
                  leading: s.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(s.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.favorite, color: AppColors.terracotta),
                  title: Text(s.name),
                  subtitle: Text(s.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(musicRepositoryProvider).removeFromOurStory(weddingId, s.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Buscar canción'),
        onPressed: () => _searchAndAdd(context, ref),
      ),
    );
  }

  void _searchAndAdd(BuildContext context, WidgetRef ref) {
    final queryCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buscar canción'),
        content: TextField(
          controller: queryCtrl,
          decoration: const InputDecoration(labelText: 'Canción o artista'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final results = await ref.read(spotifyRepositoryProvider).search(queryCtrl.text.trim());
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) _showResults(context, ref, results);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showResults(BuildContext context, WidgetRef ref, List<SpotifyTrack> results) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: results
            .map((t) => ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.artist),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(musicRepositoryProvider).addToOurStory(weddingId, t, uid);
                      Navigator.pop(context);
                    },
                    child: const Text('Agregar'),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
