import '../entities/savings.dart';

abstract class SavingsRepository {
  Stream<SavingsGoal> watchGoal(String weddingId);
  Future<void> setGoal(String weddingId, double targetAmount);

  Stream<List<SavingsEntry>> watchEntries(String weddingId);
  Future<void> addEntry(String weddingId, SavingsEntry entry);

  /// Borra un registro de ahorro. Si vino de una casilla del rasca y
  /// gana (source == 'rasca_y_gana'), también revierte esa casilla a
  /// "no completada" — pensado para corregir un clic de más.
  Future<void> deleteEntry(String weddingId, SavingsEntry entry);

  Stream<ScratchCard?> watchScratchCard(String weddingId, String memberUid);
  Future<void> createScratchCard(String weddingId, String memberUid, double target);

  /// Marca una casilla como completada Y registra el ahorro correspondiente
  /// como SavingsEntry en un solo batch (para que ambos queden consistentes).
  Future<void> completeCell(
    String weddingId,
    String memberUid,
    int cellIndex,
    ScratchCard current,
  );
}
