import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/music_repository_impl.dart';
import '../../../data/repositories/spotify_repository_impl.dart';
import '../../../data/repositories/spotify_sync_repository_impl.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/spotify_integration.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../domain/repositories/spotify_repository.dart';
import '../../../domain/repositories/spotify_sync_repository.dart';
import '../../auth/application/auth_providers.dart';

const _workerBaseUrl = String.fromEnvironment(
  'STORAGE_WORKER_URL',
  defaultValue: 'https://vowly-storage-worker.REEMPLAZAR.workers.dev',
);

// El client_id NO es secreto (a diferencia del client_secret) — Spotify
// lo espera visible en la URL de autorización que abre el navegador.
// Se pasa por --dart-define para no tenerlo hardcodeado en el repo,
// pero si prefieres puedes ponerlo fijo aquí, es información pública.
const _spotifyClientId = String.fromEnvironment('SPOTIFY_CLIENT_ID', defaultValue: '');

final _dioProvider = Provider<Dio>((ref) => Dio());

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  return SpotifyRepositoryImpl(ref.watch(_dioProvider), _workerBaseUrl);
});

final spotifySyncRepositoryProvider = Provider<SpotifySyncRepository>((ref) {
  return SpotifySyncRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(_dioProvider),
    _workerBaseUrl,
    _spotifyClientId,
  );
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepositoryImpl(ref.watch(firestoreProvider));
});

final songsStreamProvider = StreamProvider.family<List<Song>, String>((ref, weddingId) {
  return ref.watch(musicRepositoryProvider).watchSongs(weddingId);
});

final ourStoryStreamProvider = StreamProvider.family<List<Song>, String>((ref, weddingId) {
  return ref.watch(musicRepositoryProvider).watchOurStory(weddingId);
});

final spotifyIntegrationStreamProvider =
    StreamProvider.family<SpotifyIntegration?, String>((ref, weddingId) {
  return ref.watch(spotifySyncRepositoryProvider).watchIntegration(weddingId);
});
