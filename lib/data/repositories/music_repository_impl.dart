import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/spotify_track.dart';
import '../../domain/repositories/music_repository.dart';

class MusicRepositoryImpl implements MusicRepository {
  MusicRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  Map<String, dynamic> _trackToSongMap(SpotifyTrack track, String addedByUid, {String? category}) {
    return Song(
      id: '',
      spotifyTrackId: track.spotifyTrackId,
      name: track.name,
      artist: track.artist,
      album: track.album,
      imageUrl: track.imageUrl,
      durationMs: track.durationMs,
      spotifyUrl: track.spotifyUrl,
      addedAt: DateTime.now(),
      addedBy: addedByUid,
      votes: 0,
      status: SongStatus.pendiente,
      category: category,
      isFavorite: false,
      isEssential: false,
      isDoNotPlay: false,
    ).toMap();
  }

  @override
  Stream<List<Song>> watchSongs(String weddingId) {
    return FirestoreRefs(_db, weddingId).songs.snapshots().map(
          (snap) => snap.docs.map((d) => Song.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> addSong(String weddingId, SpotifyTrack track, String addedByUid, {String? category}) {
    return FirestoreRefs(_db, weddingId)
        .songs
        .add(_trackToSongMap(track, addedByUid, category: category));
  }

  @override
  Future<void> toggleVote(String weddingId, String songId, String uid) async {
    final refs = FirestoreRefs(_db, weddingId);
    final songRef = refs.songs.doc(songId);
    final voteRef = songRef.collection('votes').doc(uid);

    await _db.runTransaction((tx) async {
      final voteSnap = await tx.get(voteRef);
      final songSnap = await tx.get(songRef);
      if (!songSnap.exists) return;

      final currentVotes = (songSnap.data()?['votes'] as num?)?.toInt() ?? 0;

      if (voteSnap.exists) {
        tx.delete(voteRef);
        tx.update(songRef, {'votes': (currentVotes - 1).clamp(0, 1 << 30)});
      } else {
        tx.set(voteRef, {'value': true});
        tx.update(songRef, {'votes': currentVotes + 1});
      }
    });
  }

  @override
  Future<bool> hasVoted(String weddingId, String songId, String uid) async {
    final doc =
        await FirestoreRefs(_db, weddingId).songs.doc(songId).collection('votes').doc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> updateStatus(String weddingId, String songId, SongStatus status) {
    return FirestoreRefs(_db, weddingId).songs.doc(songId).update({'status': status.name});
  }

  @override
  Future<void> setFlags(
    String weddingId,
    String songId, {
    bool? isFavorite,
    bool? isEssential,
    bool? isDoNotPlay,
  }) {
    final updates = <String, dynamic>{};
    if (isFavorite != null) updates['isFavorite'] = isFavorite;
    if (isEssential != null) updates['isEssential'] = isEssential;
    if (isDoNotPlay != null) updates['isDoNotPlay'] = isDoNotPlay;
    if (updates.isEmpty) return Future.value();
    return FirestoreRefs(_db, weddingId).songs.doc(songId).update(updates);
  }

  @override
  Future<void> setCategory(String weddingId, String songId, String? category) {
    return FirestoreRefs(_db, weddingId).songs.doc(songId).update({'category': category});
  }

  @override
  Future<void> deleteSong(String weddingId, String songId) {
    return FirestoreRefs(_db, weddingId).songs.doc(songId).delete();
  }

  @override
  Stream<List<Song>> watchOurStory(String weddingId) {
    return FirestoreRefs(_db, weddingId).ourStory.snapshots().map(
          (snap) => snap.docs.map((d) => Song.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> addToOurStory(String weddingId, SpotifyTrack track, String addedByUid) {
    return FirestoreRefs(_db, weddingId).ourStory.add(_trackToSongMap(track, addedByUid));
  }

  @override
  Future<void> removeFromOurStory(String weddingId, String songId) {
    return FirestoreRefs(_db, weddingId).ourStory.doc(songId).delete();
  }
}
