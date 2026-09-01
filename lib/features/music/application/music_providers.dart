import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/music_repository_impl.dart';
import '../../../data/repositories/spotify_repository_impl.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/music_repository.dart';
import '../../../domain/repositories/spotify_repository.dart';
import '../../auth/application/auth_providers.dart';

const _workerBaseUrl = String.fromEnvironment(
  'STORAGE_WORKER_URL',
  defaultValue: 'https://vowly-storage-worker.REEMPLAZAR.workers.dev',
);

final _dioProvider = Provider<Dio>((ref) => Dio());

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  return SpotifyRepositoryImpl(ref.watch(_dioProvider), _workerBaseUrl);
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
