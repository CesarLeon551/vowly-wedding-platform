import '../entities/budget_category.dart';
import '../entities/expense.dart';

abstract class BudgetRepository {
  Stream<List<BudgetCategory>> watchCategories(String weddingId);
  Future<void> upsertCategory(String weddingId, BudgetCategory category);
  Future<void> deleteCategory(String weddingId, String categoryId);

  Stream<List<Expense>> watchExpenses(String weddingId);
  Future<void> upsertExpense(String weddingId, Expense expense);
  Future<void> deleteExpense(String weddingId, String expenseId);
}
