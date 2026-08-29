class DashboardStats {
  const DashboardStats({
    required this.daysRemaining,
    required this.plannedBudget,
    required this.spent,
    required this.saved,
    required this.totalGuests,
    required this.confirmedGuests,
    required this.pendingGuests,
    required this.notAttendingGuests,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.vendorsHired,
    required this.upcomingTasks,
  });

  final int daysRemaining;

  final double plannedBudget;
  final double spent;
  final double saved;
  double get pending => (plannedBudget - spent).clamp(0, double.infinity);

  final int totalGuests;
  final int confirmedGuests;
  final int pendingGuests;
  final int notAttendingGuests;

  final int tasksCompleted;
  final int tasksPending;
  final int vendorsHired;

  /// Tareas con fecha límite en los próximos 14 días, ya ordenadas.
  final List<UpcomingTask> upcomingTasks;

  /// Alertas derivadas — no se guardan en Firestore, se calculan aquí
  /// mismo a partir de los datos ya cargados (evita otra colección solo
  /// para esto en el MVP; ver `notifications` en el modelo de datos si
  /// más adelante se necesitan alertas persistentes o push).
  List<String> get alerts {
    final list = <String>[];
    if (pendingGuests > 0) {
      list.add('$pendingGuests invitados todavía no confirman.');
    }
    if (plannedBudget > 0 && spent > plannedBudget) {
      list.add('El gasto ya superó el presupuesto planeado.');
    }
    if (tasksPending > 0 && daysRemaining <= 30) {
      list.add('Quedan $tasksPending tareas pendientes y faltan $daysRemaining días.');
    }
    return list;
  }
}

class UpcomingTask {
  const UpcomingTask({required this.name, required this.dueDate});
  final String name;
  final DateTime dueDate;
}
