import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/savings.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/budget_providers.dart';
import 'scratch_card_screen.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final weddingId = user?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final goalAsync = ref.watch(savingsGoalStreamProvider(weddingId));
    final entriesAsync = ref.watch(savingsEntriesStreamProvider(weddingId));
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Ahorro')),
      body: goalAsync.when(
        data: (goal) {
          final entries = entriesAsync.valueOrNull ?? [];
          final saved = entries.fold<double>(0, (sum, e) => sum + e.amount);
          final remaining = (goal.targetAmount - saved).clamp(0, double.infinity);
          final percent = goal.targetAmount > 0 ? (saved / goal.targetAmount).clamp(0, 1) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Meta: ${currency.format(goal.targetAmount)}',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => _editGoal(context, ref, weddingId, goal.targetAmount),
                            child: const Text('Editar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent.toDouble(),
                          minHeight: 12,
                          backgroundColor: AppColors.blush.withOpacity(0.3),
                          color: AppColors.sage,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${currency.format(saved)} ahorrados · ${currency.format(remaining)} restante'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.grid_view),
                label: const Text('Mi tarjeta de rasca y gana'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScratchCardScreen(
                      weddingId: weddingId,
                      memberUid: user!.uid,
                      goalAmount: goal.targetAmount,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Registrar ahorro manual'),
                onPressed: () => _addManualEntry(context, ref, weddingId, user!.uid),
              ),
              const SizedBox(height: 24),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (entries.isEmpty) const Text('Sin registros todavía.'),
              ...entries.map((e) => ListTile(
                    leading: Icon(e.source == 'rasca_y_gana' ? Icons.grid_view : Icons.savings_outlined),
                    title: Text(currency.format(e.amount)),
                    subtitle: Text(DateFormat.yMMMd('es_MX').format(e.date)),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _editGoal(BuildContext context, WidgetRef ref, String weddingId, double current) {
    final ctrl = TextEditingController(text: current == 0 ? '' : current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Meta de ahorro'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto (MXN)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
              await ref.read(savingsRepositoryProvider).setGoal(weddingId, amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _addManualEntry(BuildContext context, WidgetRef ref, String weddingId, String uid) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar ahorro'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto (MXN)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
              if (amount > 0) {
                await ref.read(savingsRepositoryProvider).addEntry(
                      weddingId,
                      SavingsEntry(id: '', amount: amount, date: DateTime.now(), memberUid: uid, source: 'manual'),
                    );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
