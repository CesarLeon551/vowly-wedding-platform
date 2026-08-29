import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_providers.dart';
import '../../application/wedding_providers.dart';

class CreateWeddingScreen extends ConsumerStatefulWidget {
  const CreateWeddingScreen({super.key});

  @override
  ConsumerState<CreateWeddingScreen> createState() => _CreateWeddingScreenState();
}

class _CreateWeddingScreenState extends ConsumerState<CreateWeddingScreen> {
  final _nameCtrl = TextEditingController(text: 'Nuestra Boda');
  DateTime? _date;
  bool _loading = false;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_date == null) {
      setState(() => _error = 'Elige la fecha de la boda.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(weddingRepositoryProvider).createWedding(
            coupleUid: user.uid,
            coupleDisplayName: user.displayName ?? 'Novio/a',
            name: _nameCtrl.text.trim(),
            date: _date!,
          );
      // authStateProvider se re-resuelve (el router escucha cambios de
      // sesión, pero aquí forzamos un refresh leyendo de nuevo):
      ref.invalidate(authStateProvider);
    } catch (e) {
      setState(() => _error = 'No se pudo crear la boda. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null ? 'Elegir fecha' : DateFormat.yMMMMd('es_MX').format(_date!);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear nuestra boda')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la boda'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateLabel),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
