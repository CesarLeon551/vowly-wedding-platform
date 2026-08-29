import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/storage_repository.dart';
import '../repositories/storage_repository_impl.dart';
import '../../features/auth/application/auth_providers.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

/// URL pública del Cloudflare Worker una vez desplegado. Se reemplaza
/// aquí (o mejor, vía --dart-define en build) cuando exista.
const _workerBaseUrl = String.fromEnvironment(
  'STORAGE_WORKER_URL',
  defaultValue: 'https://vowly-storage-worker.REEMPLAZAR.workers.dev',
);

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(dioProvider),
    _workerBaseUrl,
  );
});
