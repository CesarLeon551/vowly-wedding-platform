import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/guest.dart';
import '../../application/guests_providers.dart';

class AddGuestScreen extends ConsumerStatefulWidget {
  const AddGuestScreen({super.key, required this.weddingId, this.existing});

  final String weddingId;
  final Guest? existing;

  @override
  ConsumerState<AddGuestScreen> createState() => _AddGuestScreenState();
}

class _AddGuestScreenState extends ConsumerState<AddGuestScreen> {
  late final _firstNameCtrl = TextEditingController(text: widget.existing?.firstName);
  late final _lastNameCtrl = TextEditingController(text: widget.existing?.lastName);
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone);
  late final _groupCtrl = TextEditingController(text: widget.existing?.group);
  late final _allowedCompanionsCtrl =
      TextEditingController(text: '${widget.existing?.allowedCompanions ?? 0}');
  bool _loading = false;

  Future<void> _submit() async {
    if (_firstNameCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);
    await ref.read(guestRepositoryProvider).upsertGuest(
          widget.weddingId,
          Guest(
            id: widget.existing?.id ?? '',
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            group: _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
            allowedCompanions: int.tryParse(_allowedCompanionsCtrl.text) ?? 0,
            companions: widget.existing?.companions ?? [],
            isAdult: widget.existing?.isAdult ?? true,
            rsvpStatus: widget.existing?.rsvpStatus ?? RsvpStatus.pendiente,
            dietaryRestrictions: widget.existing?.dietaryRestrictions,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(guestRepositoryProvider).deleteGuest(widget.weddingId, widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nuevo invitado' : 'Editar invitado'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 16),
          TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Apellido')),
          const SizedBox(height: 16),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 16),
          TextField(
            controller: _groupCtrl,
            decoration: const InputDecoration(labelText: 'Grupo/familia (ej. Familia de la novia)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _allowedCompanionsCtrl,
            decoration: const InputDecoration(labelText: 'Acompañantes permitidos'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
