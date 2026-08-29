import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/repositories/storage_repository.dart';

/// Storage sobre Cloudflare R2 (S3-compatible), no Firebase Storage.
///
/// Por qué no Firebase Storage: desde el 3 de febrero de 2026, Firebase
/// exige el plan Blaze (tarjeta vinculada) solo para *aprovisionar* un
/// bucket, aunque el consumo real sea $0.
///
/// Por qué no Cloud Functions para firmar las URLs: desplegar CUALQUIER
/// Cloud Function también exige Blaze (usa Cloud Build + Artifact
/// Registry por debajo), así que no evita el problema, solo lo mueve.
///
/// Solución: el que firma las URLs es un Cloudflare Worker
/// (`/cloudflare-worker`), que corre en el plan gratis de Cloudflare
/// (100K requests/día, SIN tarjeta). El cliente Flutter solo manda su
/// Firebase ID Token al Worker; el Worker lo valida y firma la URL de
/// subida hacia R2. El secret de R2 nunca sale del Worker.
class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl(this._auth, this._dio, this._workerBaseUrl);

  final fb.FirebaseAuth _auth;
  final Dio _dio;

  /// URL del Worker desplegado, ej. https://vowly-storage-worker.tu-cuenta.workers.dev
  final String _workerBaseUrl;

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay sesión activa.');
    final token = await user.getIdToken();
    if (token == null) throw StateError('No se pudo obtener el token de sesión.');
    return token;
  }

  @override
  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    final token = await _idToken();

    final signResponse = await _dio.post(
      '$_workerBaseUrl/upload-url',
      data: {'path': path, 'contentType': contentType},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final uploadUrl = signResponse.data['uploadUrl'] as String;
    final publicUrl = signResponse.data['publicUrl'] as String;

    await _dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': contentType},
        validateStatus: (status) => status != null && status < 300,
      ),
    );

    return publicUrl;
  }

  @override
  Future<void> deleteFile(String path) async {
    final token = await _idToken();
    await _dio.post(
      '$_workerBaseUrl/delete',
      data: {'path': path},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
