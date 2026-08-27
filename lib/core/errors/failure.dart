/// Representa un error de negocio ya "traducido" para la UI.
/// Los repositorios nunca dejan escapar excepciones de Firebase hacia arriba;
/// las capturan y devuelven un [Failure] con un mensaje entendible.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Problema de conexión. Intenta de nuevo.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'No tienes permiso para hacer esto.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No se encontró la información.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}
