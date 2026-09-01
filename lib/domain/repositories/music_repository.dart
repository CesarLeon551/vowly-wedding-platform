import '../entities/song.dart';
import '../entities/spotify_track.dart';

abstract class MusicRepository {
  Stream<List<Song>> watchSongs(String weddingId);

  /// Cualquiera (novio, colaborador, invitado) puede agregar.
  Future<void> addSong(String weddingId, SpotifyTrack track, String addedByUid, {String? category});

  /// Toggle: si ya votó, quita el voto; si no, lo agrega. Ajusta el
  /// contador `votes` del documento y el registro individual en
  /// `songs/{id}/votes/{uid}` en una sola transacción.
  Future<void> toggleVote(String weddingId, String songId, String uid);

  Future<bool> hasVoted(String weddingId, String songId, String uid);

  /// Solo novios/colaborador con acceso a música (reforzado en rules).
  Future<void> updateStatus(String weddingId, String songId, SongStatus status);
  Future<void> setFlags(
    String weddingId,
    String songId, {
    bool? isFavorite,
    bool? isEssential,
    bool? isDoNotPlay,
  });
  Future<void> setCategory(String weddingId, String songId, String? category);
  Future<void> deleteSong(String weddingId, String songId);

  // "Nuestra historia" — playlist privada de los novios.
  Stream<List<Song>> watchOurStory(String weddingId);
  Future<void> addToOurStory(String weddingId, SpotifyTrack track, String addedByUid);
  Future<void> removeFromOurStory(String weddingId, String songId);
}
