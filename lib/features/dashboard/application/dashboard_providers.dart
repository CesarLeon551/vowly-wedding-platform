import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/dashboard_repository_impl.dart';
import '../../../domain/entities/dashboard_stats.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../auth/application/auth_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(firestoreProvider));
});

final dashboardStatsProvider = StreamProvider.family<DashboardStats, String>((ref, weddingId) {
  return ref.watch(dashboardRepositoryProvider).watchStats(weddingId);
});
