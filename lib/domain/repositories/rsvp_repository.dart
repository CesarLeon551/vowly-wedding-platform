import '../entities/guest.dart';
import '../entities/wedding.dart';

abstract class RsvpRepository {
  /// Resuelve una boda pública por su slug (usado en /boda/:slug/rsvp).
  Future<Wedding?> findWeddingBySlug(String slug);

  /// Búsqueda pública por apellido — el invitado encuentra su propio
  /// registro sin necesitar cuenta. Devuelve coincidencias parciales.
  Future<List<Guest>> searchGuestsByLastName(String weddingId, String lastName);

  /// Solo puede tocar los campos de RSVP (ver Guest.toRsvpUpdateMap) —
  /// reforzado también en Firestore Security Rules, no solo aquí.
  Future<void> submitRsvp(String weddingId, Guest guest);
}
