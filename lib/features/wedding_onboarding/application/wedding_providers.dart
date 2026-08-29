import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../domain/repositories/wedding_repository.dart';
import '../../auth/application/auth_providers.dart';

final weddingRepositoryProvider = Provider<WeddingRepository>((ref) {
  return WeddingRepositoryImpl(ref.watch(firestoreProvider));
});
