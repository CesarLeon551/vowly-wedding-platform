import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../application/budget_providers.dart';

class ScratchCardScreen extends ConsumerWidget {
  const ScratchCardScreen({
    super.key,
    required this.weddingId,
    required this.memberUid,
    required this.goalAmount,
  });

  final String weddingId;
  final String memberUid;
  final double goalAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(scratchCardStreamProvider((weddingId: weddingId, uid: memberUid)));
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Rasca y gana')),
      body: cardAsync.when(
        data: (card) {
          if (card == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Todavía no tienes tarjeta. Se genera en base a la meta de ahorro actual.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: goalAmount <= 0
                          ? null
                          : () => ref.read(savingsRepositoryProvider).createScratchCard(
                                weddingId,
                                memberUid,
                                goalAmount,
                              ),
                      child: const Text('Generar mi tarjeta'),
                    ),
                    if (goalAmount <= 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Primero define una meta de ahorro mayor a \$0.',
                            style: TextStyle(color: AppColors.danger)),
                      ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Completado: ${currency.format(card.totalCompleted)}'),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: card.cells.length,
                    itemBuilder: (context, i) {
                      final cell = card.cells[i];
                      return GestureDetector(
                        onTap: cell.completed
                            ? null
                            : () => ref.read(savingsRepositoryProvider).completeCell(
                                  weddingId,
                                  memberUid,
                                  i,
                                  card,
                                ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cell.completed ? AppColors.sage : AppColors.terracotta,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cell.completed ? '✓' : '\$${cell.amount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
