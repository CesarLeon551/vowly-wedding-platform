import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/storage_repository.dart';
import '../repositories/storage_repository_impl.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final firebaseFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instance,
);

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepositoryImpl(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(dioProvider),
  );
});
