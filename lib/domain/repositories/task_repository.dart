import '../entities/wedding_task.dart';

abstract class TaskRepository {
  Stream<List<WeddingTask>> watchTasks(String weddingId);
  Future<void> upsertTask(String weddingId, WeddingTask task);
  Future<void> deleteTask(String weddingId, String taskId);
  Future<void> toggleComplete(String weddingId, String taskId, bool completed);

  /// Genera un checklist estándar con fechas relativas a la fecha de la
  /// boda. Solo crea las tareas que no existan ya (compara por nombre).
  Future<void> generateStandardChecklist(String weddingId, DateTime weddingDate);
}
