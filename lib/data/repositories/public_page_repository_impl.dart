import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/public_page_content.dart';
import '../../domain/repositories/public_page_repository.dart';

class PublicPageRepositoryImpl implements PublicPageRepository {
  PublicPageRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String weddingId) {
    return FirestoreRefs(_db, weddingId).publicPage.doc('content');
  }

  @override
  Stream<PublicPageContent> watchContent(String weddingId) {
    return _ref(weddingId).snapshots().map((snap) => PublicPageContent.fromMap(snap.data()));
  }

  @override
  Future<void> updateContent(String weddingId, PublicPageContent content) {
    return _ref(weddingId).set(content.toMap(), SetOptions(merge: true));
  }
}
