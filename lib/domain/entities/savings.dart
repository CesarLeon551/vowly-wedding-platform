import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  const SavingsGoal({required this.targetAmount});
  final double targetAmount;

  factory SavingsGoal.fromMap(Map<String, dynamic>? map) {
    return SavingsGoal(targetAmount: (map?['targetAmount'] as num?)?.toDouble() ?? 0);
  }

  Map<String, dynamic> toMap() => {'targetAmount': targetAmount};
}

class SavingsEntry {
  const SavingsEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.memberUid,
    this.source,
  });

  final String id;
  final double amount;
  final DateTime date;
  final String? memberUid;

  /// 'manual' o 'rasca_y_gana'
  final String? source;

  factory SavingsEntry.fromMap(String id, Map<String, dynamic> map) {
    return SavingsEntry(
      id: id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: (map['date'] as Timestamp).toDate(),
      memberUid: map['memberUid'] as String?,
      source: map['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'memberUid': memberUid,
        'source': source,
      };
}

/// Tarjeta de "rasca y gana": 48 casillas, cada una con un monto fijo.
/// Se genera una vez por miembro y se va marcando conforme completan.
class ScratchCard {
  const ScratchCard({required this.memberUid, required this.cells});

  final String memberUid;
  final List<ScratchCell> cells;

  double get totalCompleted =>
      cells.where((c) => c.completed).fold(0, (sum, c) => sum + c.amount);

  factory ScratchCard.fromMap(String memberUid, Map<String, dynamic> map) {
    final rawCells = (map['cells'] as List?) ?? [];
    return ScratchCard(
      memberUid: memberUid,
      cells: rawCells
          .map((c) => ScratchCell(
                amount: (c['amount'] as num).toDouble(),
                completed: c['completed'] as bool? ?? false,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'cells': cells.map((c) => {'amount': c.amount, 'completed': c.completed}).toList(),
      };

  /// Genera 48 casillas con montos crecientes que suman aprox. [total].
  static ScratchCard generate(String memberUid, double total) {
    const cellCount = 48;
    // Progresión simple 1x,2x,3x...48x de una unidad base, para que
    // sumen exactamente el total y se sienta como "rasca y gana" (montos
    // variados, no todos iguales).
    final unit = total / (cellCount * (cellCount + 1) / 2);
    final cells = List.generate(
      cellCount,
      (i) => ScratchCell(amount: (unit * (i + 1)).roundToDouble(), completed: false),
    )..shuffle();
    return ScratchCard(memberUid: memberUid, cells: cells);
  }
}

class ScratchCell {
  const ScratchCell({required this.amount, required this.completed});
  final double amount;
  final bool completed;

  ScratchCell copyWith({bool? completed}) =>
      ScratchCell(amount: amount, completed: completed ?? this.completed);
}
