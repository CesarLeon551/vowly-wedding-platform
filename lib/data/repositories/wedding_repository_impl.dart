import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/roles.dart';
import '../../domain/entities/collaborator_invitation.dart';
import '../../domain/entities/wedding.dart';
import '../../domain/repositories/wedding_repository.dart';

class WeddingRepositoryImpl implements WeddingRepository {
  WeddingRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  String _slugify(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final suffix = Random().nextInt(9000) + 1000;
    return '$base-$suffix';
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin 0/O/1/I para evitar confusión
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  Future<Wedding> createWedding({
    required String coupleUid,
    required String coupleDisplayName,
    required String name,
    required DateTime date,
  }) async {
    final weddingRef = _db.collection('weddings').doc();
    final slug = _slugify(name);

    final batch = _db.batch();

    batch.set(weddingRef, {
      'name': name,
      'date': Timestamp.fromDate(date),
      'coupleUids': [coupleUid],
      'slug': slug,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(weddingRef.collection('members').doc(coupleUid), {
      'role': MemberRole.novio.value,
      'displayName': coupleDisplayName,
      'permissions': {},
    });

    batch.set(_db.collection('users').doc(coupleUid), {
      'weddingId': weddingRef.id,
    });

    await batch.commit();

    return Wedding(
      id: weddingRef.id,
      name: name,
      date: date,
      coupleUids: [coupleUid],
      slug: slug,
    );
  }

  @override
  Future<CollaboratorInvitation> inviteCollaborator({
    required String weddingId,
    required String invitedEmail,
    required Map<AppModule, bool> permissions,
  }) async {
    final inviteRef = _db
        .collection('weddings')
        .doc(weddingId)
        .collection('invitations')
        .doc();

    final code = _generateInviteCode();
    final permsMap = {for (final e in permissions.entries) e.key.name: e.value};

    await inviteRef.set({
      'code': code,
      'invitedEmail': invitedEmail,
      'permissions': permsMap,
      'status': InvitationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return CollaboratorInvitation(
      id: inviteRef.id,
      code: code,
      weddingId: weddingId,
      invitedEmail: invitedEmail,
      permissions: permissions,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Wedding> joinWeddingWithCode({
    required String code,
    required String uid,
    required String displayName,
  }) async {
    // El código no es único a nivel global en el modelo de datos (vive
    // dentro de cada boda), así que se resuelve con un collectionGroup
    // — aquí SÍ funciona porque comparamos un campo normal ('code'), no
    // el ID del documento.
    final query = await _db
        .collectionGroup('invitations')
        .where('code', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw StateError('Código de invitación inválido o ya usado.');
    }

    final inviteDoc = query.docs.first;
    final weddingRef = inviteDoc.reference.parent.parent!;
    final inviteData = inviteDoc.data();

    final permsRaw = (inviteData['permissions'] as Map?)?.cast<String, dynamic>() ?? {};

    final batch = _db.batch();

    batch.set(weddingRef.collection('members').doc(uid), {
      'role': MemberRole.colaborador.value,
      'displayName': displayName,
      'permissions': permsRaw,
    });

    batch.set(_db.collection('users').doc(uid), {'weddingId': weddingRef.id});

    batch.update(inviteDoc.reference, {'status': InvitationStatus.accepted.name});

    await batch.commit();

    final weddingSnap = await weddingRef.get();
    final weddingData = weddingSnap.data()!;

    return Wedding(
      id: weddingRef.id,
      name: weddingData['name'] as String,
      date: (weddingData['date'] as Timestamp).toDate(),
      coupleUids: List<String>.from(weddingData['coupleUids'] as List),
      slug: weddingData['slug'] as String,
    );
  }

  @override
  Stream<List<CollaboratorInvitation>> watchInvitations(String weddingId) {
    return _db
        .collection('weddings')
        .doc(weddingId)
        .collection('invitations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final permsRaw = (data['permissions'] as Map?)?.cast<String, dynamic>() ?? {};
              return CollaboratorInvitation(
                id: doc.id,
                code: data['code'] as String,
                weddingId: weddingId,
                invitedEmail: data['invitedEmail'] as String,
                permissions: {
                  for (final module in AppModule.values)
                    module: permsRaw[module.name] == true,
                },
                status: InvitationStatus.values.firstWhere(
                  (s) => s.name == data['status'],
                  orElse: () => InvitationStatus.pending,
                ),
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }
}
