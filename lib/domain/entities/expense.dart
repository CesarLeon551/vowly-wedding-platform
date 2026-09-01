import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { efectivo, tarjeta, transferencia, otro }

class Expense {
  const Expense({
    required this.id,
    required this.concept,
    required this.categoryId,
    this.vendorName,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.paidBy,
    required this.deposit,
    this.notes,
    this.receiptUrl,
  });

  final String id;
  final String concept;
  final String categoryId;

  /// Texto libre por ahora — Fase 8 conecta esto a la colección real de
  /// `vendors` con un vendorId, cuando ese módulo exista.
  final String? vendorName;

  final DateTime date;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? paidBy;
  final double deposit;
  final String? notes;
  final String? receiptUrl;

  double get balance => (amount - deposit).clamp(0, double.infinity);

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      concept: map['concept'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      vendorName: map['vendorName'] as String?,
      date: (map['date'] as Timestamp).toDate(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (m) => m.name == map['paymentMethod'],
        orElse: () => PaymentMethod.otro,
      ),
      paidBy: map['paidBy'] as String?,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'concept': concept,
        'categoryId': categoryId,
        'vendorName': vendorName,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'paymentMethod': paymentMethod.name,
        'paidBy': paidBy,
        'deposit': deposit,
        'notes': notes,
        'receiptUrl': receiptUrl,
      };
}
