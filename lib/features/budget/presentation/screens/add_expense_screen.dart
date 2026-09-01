import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/expense.dart';
import '../../application/budget_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.weddingId});
  final String weddingId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _conceptCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _depositCtrl = TextEditingController(text: '0');
  final _vendorCtrl = TextEditingController();
  final _paidByCtrl = TextEditingController();
  String? _categoryId;
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.transferencia;
  bool _loading = false;

  Future<void> _submit() async {
    if (_conceptCtrl.text.trim().isEmpty || _categoryId == null) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final deposit = double.tryParse(_depositCtrl.text.replaceAll(',', '')) ?? 0;

    setState(() => _loading = true);
    await ref.read(budgetRepositoryProvider).upsertExpense(
          widget.weddingId,
          Expense(
            id: '',
            concept: _conceptCtrl.text.trim(),
            categoryId: _categoryId!,
            vendorName: _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
            date: _date,
            amount: amount,
            paymentMethod: _method,
            paidBy: _paidByCtrl.text.trim().isEmpty ? null : _paidByCtrl.text.trim(),
            deposit: deposit,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider(widget.weddingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _conceptCtrl,
            decoration: const InputDecoration(labelText: 'Concepto'),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('No se pudieron cargar las categorías: $e'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vendorCtrl,
            decoration: const InputDecoration(labelText: 'Proveedor (opcional)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Monto total'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _depositCtrl,
                  decoration: const InputDecoration(labelText: 'Anticipo pagado'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Método de pago'),
            items: PaymentMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paidByCtrl,
            decoration: const InputDecoration(labelText: '¿Quién pagó? (opcional)'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${_date.day}/${_date.month}/${_date.year}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar gasto'),
          ),
        ],
      ),
    );
  }
}
