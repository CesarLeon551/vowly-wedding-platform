import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/spotify_integration.dart';
import '../../domain/repositories/spotify_sync_repository.dart';

class SpotifySyncRepositoryImpl implements SpotifySyncRepository {
  SpotifySyncRepositoryImpl(this._db, this._dio, this._workerBaseUrl, this._spotifyClientId);

  final FirebaseFirestore _db;
  final Dio _dio;
  final String _workerBaseUrl;
  final String _spotifyClientId;

  DocumentReference<Map<String, dynamic>> _integrationRef(String weddingId) {
    return _db
        .collection('weddings')
        .doc(weddingId)
        .collection('integrations')
        .doc('spotify');
  }

  @override
  String buildAuthorizeUrl(String weddingId) {
    final redirectUri = Uri.encodeComponent('$_workerBaseUrl/spotify/auth/callback');
    const scope = 'playlist-modify-private playlist-modify-public';
    return 'https://accounts.spotify.com/authorize'
        '?client_id=$_spotifyClientId'
        '&response_type=code'
        '&redirect_uri=$redirectUri'
        '&scope=${Uri.encodeComponent(scope)}'
        '&state=$weddingId';
  }

  @override
  Stream<SpotifyIntegration?> watchIntegration(String weddingId) {
    return _integrationRef(weddingId)
        .snapshots()
        .map((snap) => snap.exists ? SpotifyIntegration.fromMap(snap.data()!) : null);
  }

  @override
  Future<void> saveIntegration(String weddingId, SpotifyIntegration integration) {
    return _integrationRef(weddingId).set(integration.toMap());
  }

  @override
  Future<void> disconnect(String weddingId) {
    return _integrationRef(weddingId).delete();
  }

  @override
  Future<bool> addTrackToSpotify(
    String weddingId,
    SpotifyIntegration integration,
    String spotifyTrackId,
  ) => _syncTrack(integration, spotifyTrackId, add: true);

  @override
  Future<bool> removeTrackFromSpotify(
    String weddingId,
    SpotifyIntegration integration,
    String spotifyTrackId,
  ) => _syncTrack(integration, spotifyTrackId, add: false);

  Future<bool> _syncTrack(SpotifyIntegration integration, String spotifyTrackId, {required bool add}) async {
    try {
      await _dio.post(
        '$_workerBaseUrl/spotify/playlist/${add ? 'add-track' : 'remove-track'}',
        data: {
          'refreshToken': integration.refreshToken,
          'playlistId': integration.playlistId,
          'spotifyTrackId': spotifyTrackId,
        },
      );
      return true;
    } catch (_) {
      // Mejor esfuerzo: si Spotify falla (ver notas de Fase 7 sobre 403
      // intermitentes en modo desarrollo), la app sigue funcionando —
      // solo no se reflejó en la playlist real esta vez. El botón
      // "Sincronizar ahora" permite reintentar más tarde.
      return false;
    }
  }
}
