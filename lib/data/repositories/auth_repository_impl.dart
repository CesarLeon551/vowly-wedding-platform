import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/constants/roles.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Nota de diseño: por ahora un usuario pertenece a UNA boda. Si en el
/// futuro (SaaS) un mismo uid participa en varias, esto se resuelve
/// buscando en un índice `userWeddings/{uid}` en vez de un solo
/// collectionGroup query como se hace aquí.
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
    final membershipQuery = await _db
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: fbUser.uid)
        .limit(1)
        .get();

    if (membershipQuery.docs.isEmpty) {
      // Autenticado pero sin boda asociada todavía (recién registrado).
      return AppUser(
        uid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName,
      );
    }

    final doc = membershipQuery.docs.first;
    final weddingId = doc.reference.parent.parent!.id;
    final data = doc.data();

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
  Future<void> signOut() => _auth.signOut();
}
