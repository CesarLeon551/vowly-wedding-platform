import 'package:cloud_firestore/cloud_firestore.dart';

enum SongStatus { pendiente, aprobada, rechazada }

/// Categorías sugeridas por momento de la boda (del plan de Fase 1).
/// Se guarda como texto libre en vez de enum cerrado para que los
/// novios puedan escribir una categoría propia si quieren.
const kSuggestedCategories = [
  'Ceremonia — Entrada del novio',
  'Ceremonia — Entrada de la novia',
  'Ceremonia — Firma',
  'Ceremonia — Salida',
  'Recepción — Entrada de los novios',
  'Recepción — Comida',
  'Recepción — Brindis',
  'Fiesta — Cumbia',
  'Fiesta — Banda',
  'Fiesta — Norteñas',
  'Fiesta — Rancheras',
  'Fiesta — Reggaetón',
  'Fiesta — Pop',
  'Fiesta — Electrónica',
  'Fiesta — Románticas',
  'Momento especial — Primer baile',
  'Momento especial — Baile con padres',
  'Sin categoría',
];

class Song {
  const Song({
    required this.id,
    required this.spotifyTrackId,
    required this.name,
    required this.artist,
    required this.album,
    this.imageUrl,
    required this.durationMs,
    required this.spotifyUrl,
    required this.addedAt,
    required this.addedBy,
    required this.votes,
    required this.status,
    this.category,
    required this.isFavorite,
    required this.isEssential,
    required this.isDoNotPlay,
  });

  final String id;
  final String spotifyTrackId;
  final String name;
  final String artist;
  final String album;
  final String? imageUrl;
  final int durationMs;
  final String spotifyUrl;
  final DateTime addedAt;
  final String addedBy;
  final int votes;
  final SongStatus status;
  final String? category;
  final bool isFavorite;
  final bool isEssential;
  final bool isDoNotPlay;

  factory Song.fromMap(String id, Map<String, dynamic> map) {
    return Song(
      id: id,
      spotifyTrackId: map['spotifyTrackId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      album: map['album'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      spotifyUrl: map['spotifyUrl'] as String? ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: map['addedBy'] as String? ?? '',
      votes: (map['votes'] as num?)?.toInt() ?? 0,
      status: SongStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SongStatus.pendiente,
      ),
      category: map['category'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isEssential: map['isEssential'] as bool? ?? false,
      isDoNotPlay: map['isDoNotPlay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'spotifyTrackId': spotifyTrackId,
        'name': name,
        'artist': artist,
        'album': album,
        'imageUrl': imageUrl,
        'durationMs': durationMs,
        'spotifyUrl': spotifyUrl,
        'addedAt': Timestamp.fromDate(addedAt),
        'addedBy': addedBy,
        'votes': votes,
        'status': status.name,
        'category': category,
        'isFavorite': isFavorite,
        'isEssential': isEssential,
        'isDoNotPlay': isDoNotPlay,
      };
}
