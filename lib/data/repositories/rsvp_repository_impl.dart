import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/guest.dart';
import '../../domain/entities/wedding.dart';
import '../../domain/repositories/rsvp_repository.dart';

/// Todo aquí corre SIN autenticación (invitados no tienen cuenta).
/// La protección real vive en firestore.rules — este repositorio solo
/// pide lo mínimo necesario, nunca el resto de datos administrativos.
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
  Future<List<Guest>> searchGuestsByLastName(String weddingId, String lastName) async {
    // MVP: sin índice de búsqueda dedicado, se trae la lista completa de
    // invitados (permitido por Security Rules públicamente, ver nota en
    // firestore.rules) y se filtra en el cliente. Funciona bien para
    // listas de boda típicas (decenas a un par de cientos); si esto
    // crece mucho, conviene mover la búsqueda a un campo indexado en
    // minúsculas o a un servicio de búsqueda dedicado.
    final snap = await FirestoreRefs(_db, weddingId).guests.get();
    final query = lastName.trim().toLowerCase();

    return snap.docs
        .map((d) => Guest.fromMap(d.id, d.data()))
        .where((g) => g.lastName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Future<void> submitRsvp(String weddingId, Guest guest) {
    return FirestoreRefs(_db, weddingId)
        .guests
        .doc(guest.id)
        .update(guest.toRsvpUpdateMap());
  }
}
