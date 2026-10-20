import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedImage {
  const PickedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Abre el selector de archivos del navegador, redimensiona la imagen
/// (lado mayor <= [maxSide]) y la recomprime a JPEG antes de subirla.
/// Una foto de celular pesa 4-8 MB; así queda en ~300-600 KB y la
/// invitación carga rápido en datos móviles.
///
/// Devuelve null si el usuario cancela. Si cancela, el Future del
/// evento 'change' nunca completa — es inofensivo (no hay estado de UI
/// asociado hasta que se elige un archivo).
Future<PickedImage?> pickAndOptimizeImage({int maxSide = 1920, double quality = 0.85}) async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;

  final file = input.files?.first;
  if (file == null) return null;

  final dataUrl = await _readAsDataUrl(file);

  final img = html.ImageElement();
  final loaded = Completer<void>();
  img.onLoad.first.then((_) {
    if (!loaded.isCompleted) loaded.complete();
  });
  img.onError.first.then((_) {
    if (!loaded.isCompleted) loaded.completeError('El archivo no es una imagen válida.');
  });
  img.src = dataUrl;
  await loaded.future;

  final w = img.naturalWidth;
  final h = img.naturalHeight;
  final longest = w > h ? w : h;
  final scale = longest > maxSide ? maxSide / longest : 1.0;
  final cw = (w * scale).round();
  final ch = (h * scale).round();

  final canvas = html.CanvasElement(width: cw, height: ch);
  canvas.context2D.drawImageScaled(img, 0, 0, cw, ch);
  final jpegDataUrl = canvas.toDataUrl('image/jpeg', quality);

  return PickedImage(
    bytes: base64Decode(jpegDataUrl.split(',').last),
    contentType: 'image/jpeg',
  );
}

Future<String> _readAsDataUrl(html.File file) {
  final completer = Completer<String>();
  final reader = html.FileReader();
  reader.onLoad.listen((_) => completer.complete(reader.result as String));
  reader.onError.listen((_) => completer.completeError('No se pudo leer el archivo.'));
  reader.readAsDataUrl(file);
  return completer.future;
}
