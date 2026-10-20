import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/guest.dart';
import '../../domain/entities/wedding.dart';
import '../../domain/repositories/rsvp_repository.dart';

class RsvpRepositoryImpl implements RsvpRepository {
  RsvpRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<Wedding?> findWeddingBySlug(String slug) async {
    final query = await _db.collection('weddings').where('slug', isEqualTo: slug).limit(1).get();
    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final data = doc.data();
    return Wedding(
      id: doc.id,
      name: data['name'] as String,
      date: (data['date'] as Timestamp).toDate(),
      coupleUids: List<String>.from(data['coupleUids'] as List),
      slug: data['slug'] as String,
    );
  }

  @override
  Future<Guest?> getGuestById(String weddingId, String guestId) async {
    final doc = await FirestoreRefs(_db, weddingId).guests.doc(guestId).get();
    if (!doc.exists) return null;
    return Guest.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<void> submitRsvp(String weddingId, Guest guest) {
    return FirestoreRefs(_db, weddingId).guests.doc(guest.id).update(guest.toRsvpUpdateMap());
  }
}
