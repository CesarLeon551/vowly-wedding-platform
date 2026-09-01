class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.plannedAmount,
  });

  final String id;
  final String name;
  final double plannedAmount;

  factory BudgetCategory.fromMap(String id, Map<String, dynamic> map) {
    return BudgetCategory(
      id: id,
      name: map['name'] as String? ?? '',
      plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'plannedAmount': plannedAmount,
      };
}
