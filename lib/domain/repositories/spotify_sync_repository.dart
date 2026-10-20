import '../entities/spotify_integration.dart';

abstract class SpotifySyncRepository {
  /// URL a la que se manda al usuario para autorizar la app en Spotify.
  /// El client_id no es secreto — se puede construir en el cliente.
  String buildAuthorizeUrl(String weddingId);

  Stream<SpotifyIntegration?> watchIntegration(String weddingId);

  /// Llamado desde la pantalla de callback (/spotify-connected) una vez
  /// que el Worker ya intercambió el código y creó la playlist — solo
  /// falta guardar el resultado en Firestore.
  Future<void> saveIntegration(String weddingId, SpotifyIntegration integration);

  Future<void> disconnect(String weddingId);

  /// Agrega/quita una canción de la playlist REAL en Spotify. No lanza
  /// si falla (Spotify puede estar caído o restringido) — el estado
  /// interno de la app (aprobada/rechazada) es la fuente de verdad,
  /// esto es "mejor esfuerzo" hacia afuera.
  Future<bool> addTrackToSpotify(String weddingId, SpotifyIntegration integration, String spotifyTrackId);
  Future<bool> removeTrackFromSpotify(String weddingId, SpotifyIntegration integration, String spotifyTrackId);
}
