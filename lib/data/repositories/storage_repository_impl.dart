import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/storage_repository.dart';

/// Storage sobre Cloudflare R2 (S3-compatible), no Firebase Storage.
///
/// Por qué: desde el 3 de febrero de 2026, Firebase exige el plan Blaze
/// (tarjeta vinculada) solo para *aprovisionar* un bucket de Cloud Storage,
/// aunque el consumo real se quede en $0. R2 da 10GB gratis y CERO costo
/// de salida (egress) sin pedir tarjeta — así que el proyecto sigue
/// cumpliendo la restricción de "$0 y sin servicios de pago sin
/// autorización".
///
/// Las credenciales de R2 (Account ID, Access Key, Secret Key) NUNCA
/// viven en el cliente Flutter — firmar una URL de subida requiere el
/// secret key, así que eso lo hace la Cloud Function `getR2UploadUrl`
/// (ver /functions). El cliente solo pide la URL firmada y hace el PUT.
class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl(this._functions, this._dio);

  final FirebaseFunctions _functions;
  final Dio _dio;

  @override
  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    final callable = _functions.httpsCallable('getR2UploadUrl');
    final result = await callable.call<Map<String, dynamic>>({
      'path': path,
      'contentType': contentType,
    });

    final uploadUrl = result.data['uploadUrl'] as String;
    final publicUrl = result.data['publicUrl'] as String;

    await _dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': contentType},
        // La URL ya viene firmada — dio no debe agregar auth propia.
        validateStatus: (status) => status != null && status < 300,
      ),
    );

    return publicUrl;
  }

  @override
  Future<void> deleteFile(String path) async {
    final callable = _functions.httpsCallable('deleteR2Object');
    await callable.call<void>({'path': path});
  }
}
