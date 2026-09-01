import '../entities/spotify_track.dart';

abstract class SpotifyRepository {
  Future<List<SpotifyTrack>> search(String query);
}
