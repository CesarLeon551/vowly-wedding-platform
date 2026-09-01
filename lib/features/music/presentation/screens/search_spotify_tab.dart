import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/song.dart';
import '../../../../domain/entities/spotify_track.dart';
import '../../application/music_providers.dart';

class SearchSpotifyTab extends ConsumerStatefulWidget {
  const SearchSpotifyTab({super.key, required this.weddingId, required this.uid});
  final String weddingId;
  final String uid;

  @override
  ConsumerState<SearchSpotifyTab> createState() => _SearchSpotifyTabState();
}

class _SearchSpotifyTabState extends ConsumerState<SearchSpotifyTab> {
  final _queryCtrl = TextEditingController();
  List<SpotifyTrack> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    if (_queryCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(spotifyRepositoryProvider).search(_queryCtrl.text.trim());
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = 'No se pudo buscar en Spotify. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(SpotifyTrack track) async {
    await ref.read(musicRepositoryProvider).addSong(widget.weddingId, track, widget.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${track.name}" agregada a la playlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(labelText: 'Canción, artista o álbum'),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Buscar'),
              ),
            ],
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final t = _results[i];
                return Card(
                  child: ListTile(
                    leading: t.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(t.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.music_note, size: 40),
                    title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${t.artist} · ${t.album} · ${t.durationLabel}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: TextButton(
                      onPressed: () => _add(t),
                      child: const Text('+ Agregar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
