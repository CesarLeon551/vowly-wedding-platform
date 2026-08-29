import '../../core/constants/roles.dart';
import '../entities/collaborator_invitation.dart';
import '../entities/wedding.dart';

abstract class WeddingRepository {
  /// Crea la boda + la membresía del creador como "novio" + el índice
  /// `users/{uid}` — todo en una sola escritura atómica (batch).
  Future<Wedding> createWedding({
    required String coupleUid,
    required String coupleDisplayName,
    required String name,
    required DateTime date,
  });

  /// Genera una invitación con código corto para un colaborador.
  /// Solo puede llamarla un novio (lo valida también Security Rules).
  Future<CollaboratorInvitation> inviteCollaborator({
    required String weddingId,
    required String invitedEmail,
    required Map<AppModule, bool> permissions,
  });

  /// El usuario autenticado usa un código para unirse como colaborador.
  /// Escribe member + índice `users/{uid}` y marca la invitación como
  /// aceptada, todo en un batch.
  Future<Wedding> joinWeddingWithCode({
    required String code,
    required String uid,
    required String displayName,
  });

  Stream<List<CollaboratorInvitation>> watchInvitations(String weddingId);
}
