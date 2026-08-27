/// Abstracción de "subir un archivo y obtener su URL pública".
/// La implementación real (R2, o cualquier otro proveedor S3-compatible)
/// vive en data/ — el dominio y la UI nunca hablan directo con R2.
abstract class StorageRepository {
  /// Sube [bytes] bajo la ruta lógica [path] (p.ej. "weddings/w1/photos/x.jpg")
  /// y regresa la URL pública final del archivo ya subido.
  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    required String contentType,
  });

  Future<void> deleteFile(String path);
}
