import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/budget_repository_impl.dart';
import '../../../data/repositories/savings_repository_impl.dart';
import '../../../domain/entities/budget_category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/savings.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../../../domain/repositories/savings_repository.dart';
import '../../auth/application/auth_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(firestoreProvider));
});

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepositoryImpl(ref.watch(firestoreProvider));
});

final categoriesStreamProvider =
    StreamProvider.family<List<BudgetCategory>, String>((ref, weddingId) {
  return ref.watch(budgetRepositoryProvider).watchCategories(weddingId);
});

final expensesStreamProvider = StreamProvider.family<List<Expense>, String>((ref, weddingId) {
  return ref.watch(budgetRepositoryProvider).watchExpenses(weddingId);
});

final savingsGoalStreamProvider = StreamProvider.family<SavingsGoal, String>((ref, weddingId) {
  return ref.watch(savingsRepositoryProvider).watchGoal(weddingId);
});

final savingsEntriesStreamProvider =
    StreamProvider.family<List<SavingsEntry>, String>((ref, weddingId) {
  return ref.watch(savingsRepositoryProvider).watchEntries(weddingId);
});

final scratchCardStreamProvider =
    StreamProvider.family<ScratchCard?, ({String weddingId, String uid})>((ref, params) {
  return ref.watch(savingsRepositoryProvider).watchScratchCard(params.weddingId, params.uid);
});
