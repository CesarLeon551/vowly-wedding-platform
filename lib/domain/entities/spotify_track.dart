class SpotifyTrack {
  const SpotifyTrack({
    required this.spotifyTrackId,
    required this.name,
    required this.artist,
    required this.album,
    this.imageUrl,
    required this.durationMs,
    required this.spotifyUrl,
  });

  final String spotifyTrackId;
  final String name;
  final String artist;
  final String album;
  final String? imageUrl;
  final int durationMs;
  final String spotifyUrl;

  String get durationLabel {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      spotifyTrackId: json['spotifyTrackId'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      imageUrl: json['imageUrl'] as String?,
      durationMs: (json['durationMs'] as num).toInt(),
      spotifyUrl: json['spotifyUrl'] as String,
    );
  }
}
