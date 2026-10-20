import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/task_repository_impl.dart';
import '../../../data/repositories/vendor_repository_impl.dart';
import '../../../domain/entities/vendor.dart';
import '../../../domain/entities/wedding_task.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/repositories/vendor_repository.dart';
import '../../auth/application/auth_providers.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(ref.watch(firestoreProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(firestoreProvider));
});

final vendorsStreamProvider = StreamProvider.family<List<Vendor>, String>((ref, weddingId) {
  return ref.watch(vendorRepositoryProvider).watchVendors(weddingId);
});

final tasksStreamProvider = StreamProvider.family<List<WeddingTask>, String>((ref, weddingId) {
  return ref.watch(taskRepositoryProvider).watchTasks(weddingId);
});

/// Solo la fecha de la boda, para generar el checklist con fechas
/// relativas sin acoplar este módulo a wedding_onboarding.
final weddingDateStreamProvider = StreamProvider.family<DateTime?, String>((ref, weddingId) {
  return ref.watch(firestoreProvider).collection('weddings').doc(weddingId).snapshots().map(
        (snap) => (snap.data()?['date'] as Timestamp?)?.toDate(),
      );
});
