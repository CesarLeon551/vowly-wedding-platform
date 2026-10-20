import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/wedding_task.dart';
import '../../application/vendors_providers.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key, required this.weddingId, this.existing});

  final String weddingId;
  final WeddingTask? existing;

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _descriptionCtrl = TextEditingController(text: widget.existing?.description);
  late final _assignedToCtrl = TextEditingController(text: widget.existing?.assignedTo);
  late final _categoryCtrl = TextEditingController(text: widget.existing?.category);
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes);
  DateTime? _dueDate;
  late TaskPriority _priority = widget.existing?.priority ?? TaskPriority.media;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.existing?.dueDate;
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);
    await ref.read(taskRepositoryProvider).upsertTask(
          widget.weddingId,
          WeddingTask(
            id: widget.existing?.id ?? '',
            name: _nameCtrl.text.trim(),
            description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
            assignedTo: _assignedToCtrl.text.trim().isEmpty ? null : _assignedToCtrl.text.trim(),
            dueDate: _dueDate,
            priority: _priority,
            status: widget.existing?.status ?? TaskStatus.pendiente,
            category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(taskRepositoryProvider).deleteTask(widget.weddingId, widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nueva tarea' : 'Editar tarea'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _assignedToCtrl,
            decoration: const InputDecoration(labelText: 'Responsable'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(_dueDate == null
                ? 'Sin fecha límite'
                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Prioridad'),
            items: TaskPriority.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notas'),
            maxLines: 2,
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
