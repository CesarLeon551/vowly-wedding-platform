import 'package:dio/dio.dart';

import '../../domain/entities/spotify_track.dart';
import '../../domain/repositories/spotify_repository.dart';

/// Llama a /spotify/search en el mismo Cloudflare Worker que ya firma
/// las URLs de R2 (ver StorageRepositoryImpl) — ahí vive el secret de
/// Spotify, nunca en el cliente. No requiere sesión: los invitados sin
/// cuenta también buscan canciones.
class SpotifyRepositoryImpl implements SpotifyRepository {
  SpotifyRepositoryImpl(this._dio, this._workerBaseUrl);

  final Dio _dio;
  final String _workerBaseUrl;

  @override
  Future<List<SpotifyTrack>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _dio.get(
      '$_workerBaseUrl/spotify/search',
      queryParameters: {'q': query},
    );

    final tracks = (response.data['tracks'] as List).cast<Map<String, dynamic>>();
    return tracks.map(SpotifyTrack.fromJson).toList();
  }
}
