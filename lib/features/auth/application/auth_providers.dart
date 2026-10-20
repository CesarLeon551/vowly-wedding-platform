import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
