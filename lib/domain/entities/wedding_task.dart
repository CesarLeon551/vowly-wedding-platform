import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { baja, media, alta }

enum TaskStatus { pendiente, completada }

class WeddingTask {
  const WeddingTask({
    required this.id,
    required this.name,
    this.description,
    this.assignedTo,
    this.dueDate,
    this.priority = TaskPriority.media,
    this.status = TaskStatus.pendiente,
    this.category,
    this.notes,
  });

  final String id;
  final String name;
  final String? description;
  final String? assignedTo;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String? category;
  final String? notes;

  factory WeddingTask.fromMap(String id, Map<String, dynamic> map) {
    return WeddingTask(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      assignedTo: map['assignedTo'] as String?,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => TaskPriority.media,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatus.pendiente,
      ),
      category: map['category'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'assignedTo': assignedTo,
        'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
        'priority': priority.name,
        'status': status.name,
        'category': category,
        'notes': notes,
      };
}
