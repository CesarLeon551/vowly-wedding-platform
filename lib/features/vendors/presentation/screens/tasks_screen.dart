import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/back_to_dashboard_button.dart';
import '../../../../domain/entities/wedding_task.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/vendors_providers.dart';
import 'add_task_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _showCompleted = false;

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.alta => AppColors.danger,
        TaskPriority.media => AppColors.gold,
        TaskPriority.baja => AppColors.sage,
      };

  @override
  Widget build(BuildContext context) {
    final weddingId = ref.watch(authStateProvider).valueOrNull?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final tasksAsync = ref.watch(tasksStreamProvider(weddingId));
    final weddingDateAsync = ref.watch(weddingDateStreamProvider(weddingId));

    return Scaffold(
      appBar: AppBar(
        leading: BackToDashboardButton(weddingId: weddingId),
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: Icon(_showCompleted ? Icons.visibility_off : Icons.visibility),
            tooltip: _showCompleted ? 'Ocultar completadas' : 'Mostrar completadas',
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final visible = (_showCompleted
                  ? tasks
                  : tasks.where((t) => t.status != TaskStatus.completada).toList())
              .toList();
          visible.sort((a, b) {
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Todavía no hay tareas.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    weddingDateAsync.when(
                      data: (date) => date == null
                          ? const SizedBox.shrink()
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.checklist),
                              label: const Text('Generar checklist estándar'),
                              onPressed: () => ref
                                  .read(taskRepositoryProvider)
                                  .generateStandardChecklist(weddingId, date),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final t = visible[i];
              final overdue = t.dueDate != null &&
                  t.dueDate!.isBefore(DateTime.now()) &&
                  t.status != TaskStatus.completada;
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: t.status == TaskStatus.completada,
                    onChanged: (v) => ref
                        .read(taskRepositoryProvider)
                        .toggleComplete(weddingId, t.id, v ?? false),
                  ),
                  title: Text(
                    t.name,
                    style: t.status == TaskStatus.completada
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Text([
                    if (t.category != null) t.category!,
                    if (t.dueDate != null) DateFormat.yMMMd('es_MX').format(t.dueDate!),
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overdue)
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 4),
                      CircleAvatar(radius: 5, backgroundColor: _priorityColor(t.priority)),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddTaskScreen(weddingId: weddingId, existing: t)),
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
          MaterialPageRoute(builder: (_) => AddTaskScreen(weddingId: weddingId)),
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('Tarea'),
      ),
    );
  }
}
