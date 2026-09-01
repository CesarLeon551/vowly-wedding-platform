import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/budget_category.dart';
import '../../../../domain/entities/expense.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/budget_providers.dart';
import 'add_category_screen.dart';
import 'add_expense_screen.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingId = ref.watch(authStateProvider).valueOrNull?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesStreamProvider(weddingId));
    final expensesAsync = ref.watch(expensesStreamProvider(weddingId));
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Presupuesto'),
          bottom: const TabBar(tabs: [Tab(text: 'Gastos'), Tab(text: 'Categorías')]),
        ),
        body: TabBarView(
          children: [
            _ExpensesTab(
              weddingId: weddingId,
              categoriesAsync: categoriesAsync,
              expensesAsync: expensesAsync,
              currency: currency,
            ),
            _CategoriesTab(weddingId: weddingId, categoriesAsync: categoriesAsync, expensesAsync: expensesAsync, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.weddingId,
    required this.categoriesAsync,
    required this.expensesAsync,
    required this.currency,
  });

  final String weddingId;
  final AsyncValue<List<BudgetCategory>> categoriesAsync;
  final AsyncValue<List<Expense>> expensesAsync;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('Todavía no hay gastos registrados.'));
          }
          final categories = categoriesAsync.valueOrNull ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: expenses.length,
            itemBuilder: (context, i) {
              final e = expenses[i];
              final categoryName = categories
                  .firstWhere(
                    (c) => c.id == e.categoryId,
                    orElse: () => const BudgetCategory(id: '', name: 'Sin categoría', plannedAmount: 0),
                  )
                  .name;
              return Card(
                child: ListTile(
                  title: Text(e.concept),
                  subtitle: Text('$categoryName · ${DateFormat.yMMMd('es_MX').format(e.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (e.balance > 0)
                        Text('Saldo: ${currency.format(e.balance)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(weddingId: weddingId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Gasto'),
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({
    required this.weddingId,
    required this.categoriesAsync,
    required this.expensesAsync,
    required this.currency,
  });

  final String weddingId;
  final AsyncValue<List<BudgetCategory>> categoriesAsync;
  final AsyncValue<List<Expense>> expensesAsync;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final expenses = expensesAsync.valueOrNull ?? [];

    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Agrega tu primera categoría de presupuesto.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              final spent = expenses
                  .where((e) => e.categoryId == c.id)
                  .fold<double>(0, (sum, e) => sum + e.amount);
              final overBudget = spent > c.plannedAmount && c.plannedAmount > 0;
              return Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text('${currency.format(spent)} de ${currency.format(c.plannedAmount)}'),
                  trailing: overBudget
                      ? const Icon(Icons.warning_amber_rounded, color: AppColors.danger)
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddCategoryScreen(weddingId: weddingId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Categoría'),
      ),
    );
  }
}
