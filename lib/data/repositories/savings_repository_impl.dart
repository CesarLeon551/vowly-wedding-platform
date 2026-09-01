import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/savings.dart';
import '../../domain/repositories/savings_repository.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  SavingsRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<SavingsGoal> watchGoal(String weddingId) {
    return FirestoreRefs(_db, weddingId)
        .savingsGoal
        .snapshots()
        .map((snap) => SavingsGoal.fromMap(snap.data()));
  }

  @override
  Future<void> setGoal(String weddingId, double targetAmount) {
    return FirestoreRefs(_db, weddingId)
        .savingsGoal
        .set({'targetAmount': targetAmount}, SetOptions(merge: true));
  }

  @override
  Stream<List<SavingsEntry>> watchEntries(String weddingId) {
    return FirestoreRefs(_db, weddingId)
        .savingsEntries()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SavingsEntry.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> addEntry(String weddingId, SavingsEntry entry) {
    return FirestoreRefs(_db, weddingId).savingsEntries().add(entry.toMap());
  }

  @override
  Stream<ScratchCard?> watchScratchCard(String weddingId, String memberUid) {
    return FirestoreRefs(_db, weddingId)
        .scratchCards
        .doc(memberUid)
        .snapshots()
        .map((snap) => snap.exists ? ScratchCard.fromMap(memberUid, snap.data()!) : null);
  }

  @override
  Future<void> createScratchCard(String weddingId, String memberUid, double target) {
    final card = ScratchCard.generate(memberUid, target);
    return FirestoreRefs(_db, weddingId).scratchCards.doc(memberUid).set(card.toMap());
  }

  @override
  Future<void> completeCell(
    String weddingId,
    String memberUid,
    int cellIndex,
    ScratchCard current,
  ) async {
    final refs = FirestoreRefs(_db, weddingId);
    final cell = current.cells[cellIndex];
    if (cell.completed) return;

    final updatedCells = [...current.cells];
    updatedCells[cellIndex] = cell.copyWith(completed: true);
    final updatedCard = ScratchCard(memberUid: memberUid, cells: updatedCells);

    final batch = _db.batch();
    batch.set(refs.scratchCards.doc(memberUid), updatedCard.toMap());
    batch.set(
      refs.savingsEntries().doc(),
      {
        'amount': cell.amount,
        'date': Timestamp.now(),
        'memberUid': memberUid,
        'source': 'rasca_y_gana',
      },
    );
    await batch.commit();
  }
}
