import '../../core/constants/roles.dart';

enum InvitationStatus { pending, accepted, revoked }

/// Invitación para que alguien se una como colaborador de una boda.
/// Se identifica por un código corto que el novio comparte manualmente
/// (WhatsApp, etc.) — no se envía correo automático en este MVP.
class CollaboratorInvitation {
  const CollaboratorInvitation({
    required this.id,
    required this.code,
    required this.weddingId,
    required this.invitedEmail,
    required this.permissions,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String weddingId;
  final String invitedEmail;
  final Map<AppModule, bool> permissions;
  final InvitationStatus status;
  final DateTime createdAt;
}
