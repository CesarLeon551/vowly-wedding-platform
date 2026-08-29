import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithEmail(String email, String password);

  /// Crea la cuenta de Firebase Auth. NO crea boda ni membresía — eso
  /// lo hace WeddingRepository.createWedding por separado, así el usuario
  /// puede registrarse y luego elegir "crear boda" o "unirme con invitación".
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
