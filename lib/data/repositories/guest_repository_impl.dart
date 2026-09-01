import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/guest.dart';
import '../../domain/repositories/guest_repository.dart';

class GuestRepositoryImpl implements GuestRepository {
  GuestRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Guest>> watchGuests(String weddingId) {
    return FirestoreRefs(_db, weddingId).guests.snapshots().map(
          (snap) => snap.docs.map((d) => Guest.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> upsertGuest(String weddingId, Guest guest) {
    final ref = FirestoreRefs(_db, weddingId).guests;
    if (guest.id.isEmpty) {
      return ref.add(guest.toMap());
    }
    return ref.doc(guest.id).set(guest.toMap());
  }

  @override
  Future<void> deleteGuest(String weddingId, String guestId) {
    return FirestoreRefs(_db, weddingId).guests.doc(guestId).delete();
  }
}
