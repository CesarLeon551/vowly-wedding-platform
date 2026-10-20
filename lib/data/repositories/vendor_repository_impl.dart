import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  VendorRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Vendor>> watchVendors(String weddingId) {
    return FirestoreRefs(_db, weddingId).vendors.snapshots().map(
          (snap) => snap.docs.map((d) => Vendor.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<String> upsertVendor(String weddingId, Vendor vendor) async {
    final ref = FirestoreRefs(_db, weddingId).vendors;
    if (vendor.id.isEmpty) {
      final doc = await ref.add(vendor.toMap());
      return doc.id;
    }
    await ref.doc(vendor.id).set(vendor.toMap());
    return vendor.id;
  }

  @override
  Future<void> deleteVendor(String weddingId, String vendorId) {
    return FirestoreRefs(_db, weddingId).vendors.doc(vendorId).delete();
  }
}
