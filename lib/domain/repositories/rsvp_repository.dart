import '../entities/guest.dart';
import '../entities/wedding.dart';

abstract class RsvpRepository {
  Future<Wedding?> findWeddingBySlug(String slug);

  /// Reemplaza la búsqueda por apellido de Fase 6: cada invitado tiene
  /// un link único (/boda/:slug/i/:guestId) que ya sabe quién es, sin
  /// necesitar listar ni buscar en el resto de la colección.
  Future<Guest?> getGuestById(String weddingId, String guestId);

  Future<void> submitRsvp(String weddingId, Guest guest);
}
