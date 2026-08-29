import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/constants/roles.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Nota de diseño (revisado en Fase 3): un usuario pertenece a UNA boda
/// por ahora. La membresía se resuelve vía un índice plano
/// `users/{uid}` → {weddingId} en vez de un collectionGroup query sobre
/// `members`, porque Firestore no permite comparar por ID corto de
/// documento en un collectionGroup (solo por path completo, que aquí no
/// se conoce de antemano). Este índice se escribe en el mismo batch que
/// crea la boda o que acepta una invitación — ver WeddingRepositoryImpl.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._db);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _resolveMembership(fbUser);
    });
  }

  Future<AppUser> _resolveMembership(fb.User fbUser) async {
    final indexDoc = await _db.collection('users').doc(fbUser.uid).get();

    if (!indexDoc.exists) {
      // Autenticado pero sin boda asociada todavía (recién registrado).
      return AppUser(
        uid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName,
      );
    }

    final weddingId = indexDoc.data()!['weddingId'] as String;

    final memberDoc = await _db
        .collection('weddings')
        .doc(weddingId)
        .collection('members')
        .doc(fbUser.uid)
        .get();

    if (!memberDoc.exists) {
      // Índice desincronizado (no debería pasar si siempre se escriben
      // juntos) — se trata igual que "sin boda" en vez de tronar la app.
      return AppUser(
        uid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName,
      );
    }

    final data = memberDoc.data()!;
    final permsRaw = (data['permissions'] as Map?)?.cast<String, dynamic>() ?? {};
    final permissions = <AppModule, bool>{
      for (final module in AppModule.values)
        module: permsRaw[module.name] == true,
    };

    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email,
      displayName: (data['displayName'] as String?) ?? fbUser.displayName,
      role: MemberRole.fromString(data['role'] as String? ?? 'invitado'),
      weddingId: weddingId,
      permissions: permissions,
    );
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _resolveMembership(credential.user!);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);

    return AppUser(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
