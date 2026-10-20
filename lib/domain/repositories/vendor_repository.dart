import '../entities/vendor.dart';

abstract class VendorRepository {
  Stream<List<Vendor>> watchVendors(String weddingId);
  Future<String> upsertVendor(String weddingId, Vendor vendor);
  Future<void> deleteVendor(String weddingId, String vendorId);
}
