import 'package:cloud_firestore/cloud_firestore.dart';

/// Centraliza el acceso a las colecciones/subcolecciones definidas en el
/// modelo de datos de Fase 1. Todo cuelga de `weddings/{weddingId}`.
///
/// Mantener este archivo como única fuente de verdad de nombres de
/// colección evita typos repetidos por todo el proyecto.
class FirestoreRefs {
  FirestoreRefs(this._db, this.weddingId);

  final FirebaseFirestore _db;
  final String weddingId;

  DocumentReference<Map<String, dynamic>> get wedding =>
      _db.collection('weddings').doc(weddingId);

  CollectionReference<Map<String, dynamic>> get members =>
      wedding.collection('members');

  CollectionReference<Map<String, dynamic>> get budgetCategories =>
      wedding.collection('budgetCategories');

  CollectionReference<Map<String, dynamic>> get expenses =>
      wedding.collection('expenses');

  DocumentReference<Map<String, dynamic>> get savingsGoal =>
      wedding.collection('savings').doc('goal');

  CollectionReference<Map<String, dynamic>> savingsEntries() =>
      savingsGoal.collection('savingsEntries');

  CollectionReference<Map<String, dynamic>> get scratchCards =>
      savingsGoal.collection('scratchCards');

  CollectionReference<Map<String, dynamic>> get guests =>
      wedding.collection('guests');

  CollectionReference<Map<String, dynamic>> get vendors =>
      wedding.collection('vendors');

  CollectionReference<Map<String, dynamic>> get tasks =>
      wedding.collection('tasks');

  CollectionReference<Map<String, dynamic>> get tables =>
      wedding.collection('tables');

  CollectionReference<Map<String, dynamic>> get timelineEvents =>
      wedding.collection('timelineEvents');

  CollectionReference<Map<String, dynamic>> get songs =>
      wedding.collection('songs');

  CollectionReference<Map<String, dynamic>> get ourStory =>
      wedding.collection('ourStory');

  CollectionReference<Map<String, dynamic>> get photos =>
      wedding.collection('photos');

  CollectionReference<Map<String, dynamic>> get documents =>
      wedding.collection('documents');

  CollectionReference<Map<String, dynamic>> get notifications =>
      wedding.collection('notifications');
}
