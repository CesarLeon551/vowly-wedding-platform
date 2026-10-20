import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/wedding_task.dart';
import '../../domain/repositories/task_repository.dart';

/// (nombre, días antes de la boda, categoría). Punto de partida: el
/// usuario puede editar o borrar cualquiera después de generarlas.
const _standardChecklist = <(String, int, String)>[
  ('Definir presupuesto general', 365, 'Planeación'),
  ('Reservar salón', 330, 'Salón'),
  ('Contratar fotógrafo', 300, 'Fotografía'),
  ('Contratar banda o DJ', 300, 'Música'),
  ('Elegir vestido de novia', 270, 'Vestido'),
  ('Elegir traje de novio', 240, 'Traje'),
  ('Contratar banquete/catering', 210, 'Comida'),
  ('Enviar invitaciones', 120, 'Invitaciones'),
  ('Contratar florista/decoración', 120, 'Decoración'),
  ('Prueba de vestido', 60, 'Vestido'),
  ('Confirmar acomodo de mesas', 30, 'Mesas'),
  ('Última prueba de maquillaje/peinado', 14, 'Belleza'),
  ('Confirmar cronograma del día', 7, 'Planeación'),
  ('Pagos finales a proveedores', 3, 'Proveedores'),
];

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<WeddingTask>> watchTasks(String weddingId) {
    return FirestoreRefs(_db, weddingId).tasks.snapshots().map(
          (snap) => snap.docs.map((d) => WeddingTask.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> upsertTask(String weddingId, WeddingTask task) {
    final ref = FirestoreRefs(_db, weddingId).tasks;
    if (task.id.isEmpty) {
      return ref.add(task.toMap());
    }
    return ref.doc(task.id).set(task.toMap());
  }

  @override
  Future<void> deleteTask(String weddingId, String taskId) {
    return FirestoreRefs(_db, weddingId).tasks.doc(taskId).delete();
  }

  @override
  Future<void> toggleComplete(String weddingId, String taskId, bool completed) {
    return FirestoreRefs(_db, weddingId).tasks.doc(taskId).update({
      'status': completed ? TaskStatus.completada.name : TaskStatus.pendiente.name,
    });
  }

  @override
  Future<void> generateStandardChecklist(String weddingId, DateTime weddingDate) async {
    final ref = FirestoreRefs(_db, weddingId).tasks;
    final existing = await ref.get();
    final existingNames = existing.docs.map((d) => d.data()['name'] as String?).toSet();

    final batch = _db.batch();
    for (final (name, daysBefore, category) in _standardChecklist) {
      if (existingNames.contains(name)) continue;
      final task = WeddingTask(
        id: '',
        name: name,
        category: category,
        dueDate: weddingDate.subtract(Duration(days: daysBefore)),
        priority: daysBefore <= 30 ? TaskPriority.alta : TaskPriority.media,
      );
      batch.set(ref.doc(), task.toMap());
    }
    await batch.commit();
  }
}
