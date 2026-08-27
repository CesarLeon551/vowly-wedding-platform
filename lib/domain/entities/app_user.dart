import '../../core/constants/roles.dart';

/// Usuario autenticado + su rol dentro de UNA boda.
/// No conoce nada de Firebase — así el resto del dominio no depende
/// del backend concreto.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role,
    this.weddingId,
    this.permissions = const {},
  });

  final String uid;
  final String? email;
  final String? displayName;

  /// Null mientras no se ha resuelto su membresía en la boda.
  final MemberRole? role;
  final String? weddingId;

  /// Solo relevante si role == colaborador.
  final Map<AppModule, bool> permissions;

  bool get isCouple => role == MemberRole.novio;
  bool get isCollaborator => role == MemberRole.colaborador;

  bool canAccess(AppModule module) {
    if (isCouple) return true;
    if (isCollaborator) return permissions[module] ?? false;
    return false;
  }
}
