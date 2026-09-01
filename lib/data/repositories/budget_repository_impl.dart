import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<BudgetCategory>> watchCategories(String weddingId) {
    return FirestoreRefs(_db, weddingId).budgetCategories.snapshots().map(
          (snap) => snap.docs.map((d) => BudgetCategory.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> upsertCategory(String weddingId, BudgetCategory category) {
    final ref = FirestoreRefs(_db, weddingId).budgetCategories;
    if (category.id.isEmpty) {
      return ref.add(category.toMap());
    }
    return ref.doc(category.id).set(category.toMap());
  }

  @override
  Future<void> deleteCategory(String weddingId, String categoryId) {
    return FirestoreRefs(_db, weddingId).budgetCategories.doc(categoryId).delete();
  }

  @override
  Stream<List<Expense>> watchExpenses(String weddingId) {
    return FirestoreRefs(_db, weddingId)
        .expenses
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> upsertExpense(String weddingId, Expense expense) {
    final ref = FirestoreRefs(_db, weddingId).expenses;
    if (expense.id.isEmpty) {
      return ref.add(expense.toMap());
    }
    return ref.doc(expense.id).set(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String weddingId, String expenseId) {
    return FirestoreRefs(_db, weddingId).expenses.doc(expenseId).delete();
  }
}
