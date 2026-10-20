class SpotifyIntegration {
  const SpotifyIntegration({
    required this.refreshToken,
    required this.playlistId,
    required this.playlistUrl,
    required this.connectedBy,
  });

  final String refreshToken;
  final String playlistId;
  final String playlistUrl;
  final String connectedBy;

  factory SpotifyIntegration.fromMap(Map<String, dynamic> map) {
    return SpotifyIntegration(
      refreshToken: map['refreshToken'] as String,
      playlistId: map['playlistId'] as String,
      playlistUrl: map['playlistUrl'] as String,
      connectedBy: map['connectedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'refreshToken': refreshToken,
        'playlistId': playlistId,
        'playlistUrl': playlistUrl,
        'connectedBy': connectedBy,
      };
}
