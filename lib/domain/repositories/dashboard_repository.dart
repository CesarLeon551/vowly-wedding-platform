import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  /// Combina varios streams de Firestore (presupuesto, invitados, tareas,
  /// proveedores) en un solo stream de estadísticas ya agregadas.
  Stream<DashboardStats> watchStats(String weddingId);
}
