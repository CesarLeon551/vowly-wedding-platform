import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/guest_repository_impl.dart';
import '../../../data/repositories/rsvp_repository_impl.dart';
import '../../../domain/entities/guest.dart';
import '../../../domain/repositories/guest_repository.dart';
import '../../../domain/repositories/rsvp_repository.dart';
import '../../auth/application/auth_providers.dart';

final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  return GuestRepositoryImpl(ref.watch(firestoreProvider));
});

final rsvpRepositoryProvider = Provider<RsvpRepository>((ref) {
  // No depende de sesión — funciona para usuarios sin login.
  return RsvpRepositoryImpl(ref.watch(firestoreProvider));
});

final guestsStreamProvider = StreamProvider.family<List<Guest>, String>((ref, weddingId) {
  return ref.watch(guestRepositoryProvider).watchGuests(weddingId);
});
