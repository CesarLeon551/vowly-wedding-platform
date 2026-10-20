import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/public_page_repository_impl.dart';
import '../../../data/repositories/rsvp_repository_impl.dart';
import '../../../domain/entities/public_page_content.dart';
import '../../../domain/repositories/public_page_repository.dart';
import '../../../domain/repositories/rsvp_repository.dart';
import '../../auth/application/auth_providers.dart';

final rsvpRepositoryProvider = Provider<RsvpRepository>((ref) {
  return RsvpRepositoryImpl(ref.watch(firestoreProvider));
});

final publicPageRepositoryProvider = Provider<PublicPageRepository>((ref) {
  return PublicPageRepositoryImpl(ref.watch(firestoreProvider));
});

final publicPageContentStreamProvider =
    StreamProvider.family<PublicPageContent, String>((ref, weddingId) {
  return ref.watch(publicPageRepositoryProvider).watchContent(weddingId);
});

final weddingSlugStreamProvider = StreamProvider.family<String?, String>((ref, weddingId) {
  return ref.watch(firestoreProvider).collection('weddings').doc(weddingId).snapshots().map(
        (snap) => snap.data()?['slug'] as String?,
      );
});

/// Da un uid utilizable para votar canciones sin pedirle cuenta al
/// invitado. No reemplaza una sesión real si ya hay una (ej. el propio
/// novio probando su link) — signInAnonymously() solo se llama si no
/// hay nadie logueado.
Future<String> ensureGuestSession(fb.FirebaseAuth auth) async {
  final current = auth.currentUser;
  if (current != null) return current.uid;
  final credential = await auth.signInAnonymously();
  return credential.user!.uid;
}
