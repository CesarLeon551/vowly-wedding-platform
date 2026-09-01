import '../entities/guest.dart';

abstract class GuestRepository {
  Stream<List<Guest>> watchGuests(String weddingId);
  Future<void> upsertGuest(String weddingId, Guest guest);
  Future<void> deleteGuest(String weddingId, String guestId);
}
