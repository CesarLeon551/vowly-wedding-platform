import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/back_to_dashboard_button.dart';
import '../../../../data/providers/storage_providers.dart';
import '../../../../domain/entities/public_page_content.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/public_page_providers.dart';
import '../../application/web_image_picker.dart';

class EditPublicPageScreen extends ConsumerStatefulWidget {
  const EditPublicPageScreen({super.key});

  @override
  ConsumerState<EditPublicPageScreen> createState() => _EditPublicPageScreenState();
}

class _EditPublicPageScreenState extends ConsumerState<EditPublicPageScreen> {
  final Map<String, TextEditingController> _ctrls = {
    for (final k in PublicPageContent.textKeys) k: TextEditingController(),
  };
  final Map<String, String?> _images = {};

  bool _loaded = false;
  bool _saving = false;
  String? _uploadingKey;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFrom(PublicPageContent content) {
    if (_loaded) return;
    for (final k in PublicPageContent.textKeys) {
      _ctrls[k]!.text = content.valueOf(k) ?? '';
    }
    for (final k in PublicPageContent.imageKeys) {
      _images[k] = content.valueOf(k);
    }
    _loaded = true;
  }

  Future<void> _pickImage(String key, String weddingId) async {
    final picked = await pickAndOptimizeImage();
    if (picked == null) return;

    setState(() => _uploadingKey = key);
    try {
      final path = 'weddings/$weddingId/public/$key-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await ref.read(storageRepositoryProvider).uploadFile(
            path: path,
            bytes: picked.bytes,
            contentType: picked.contentType,
          );
      if (mounted) setState(() => _images[key] = url);
    } catch (e) {
      // Con DioException el mensaje genérico no dice nada útil: lo que
      // importa es el cuerpo de la respuesta (el Worker explica el motivo).
      final detail = e is DioException
          ? 'HTTP ${e.response?.statusCode ?? '-'}: ${e.response?.data ?? e.message}'
          : '$e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            content: Text(
              'No se pudo subir la foto. $detail\n'
              'Si no hay respuesta del servidor, revisa el CORS (PUT) del bucket de R2.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  Future<void> _save(String weddingId) async {
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        for (final k in PublicPageContent.textKeys) k: _ctrls[k]!.text,
        for (final k in PublicPageContent.imageKeys) k: _images[k],
      };
      await ref
          .read(publicPageRepositoryProvider)
          .updateContent(weddingId, PublicPageContent.fromMap(data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _tf(String key, String label, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _ctrls[key],
        maxLines: maxLines,
        minLines: 1,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _img(String key, String label, String weddingId) {
    final url = _images[key];
    final uploading = _uploadingKey == key;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.blush.withOpacity(0.3),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      'Foto subida, pero el navegador no puede mostrarla.\n'
                      'Revisa el CORS (GET) del bucket de R2.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: uploading ? null : () => _pickImage(key, weddingId),
                icon: uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(url == null ? 'Subir foto' : 'Cambiar foto'),
              ),
              if (url != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: uploading ? null : () => setState(() => _images[key] = null),
                  child: const Text('Quitar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children, {bool expanded = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weddingId = ref.watch(authStateProvider).valueOrNull?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final contentAsync = ref.watch(publicPageContentStreamProvider(weddingId));

    return Scaffold(
      appBar: AppBar(
        leading: BackToDashboardButton(weddingId: weddingId),
        title: const Text('Editar página pública'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (_saving || !_loaded) ? null : () => _save(weddingId),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ),
      body: contentAsync.when(
        data: (content) {
          _fillFrom(content);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _group('Portada', [
                _tf('coupleNames', 'Nombres de los novios', hint: 'César y Karen'),
                _tf('heroTagline', 'Frase de la portada',
                    maxLines: 2, hint: 'Hay momentos que se vuelven eternos, y este es uno de ellos.'),
                _tf('heroLocation', 'Ciudad y estado', hint: 'La Piedad, Michoacán'),
                _img('heroImageUrl', 'Foto de portada (horizontal, mejor si es de pareja)', weddingId),
              ], expanded: true),
              _group('Nuestra historia', [
                _tf('story', 'Cuéntale a tus invitados cómo empezó todo', maxLines: 6),
              ]),
              _group('Ceremonia', [
                _tf('ceremonyTitle', 'Título', hint: 'Misa'),
                _tf('ceremonyVenue', 'Lugar', hint: 'Parroquia de San José'),
                _tf('ceremonyAddress', 'Dirección', maxLines: 2),
                _tf('ceremonyMapUrl', 'Link de Google Maps', hint: 'https://maps.app.goo.gl/...'),
                _tf('ceremonyTime', 'Hora', hint: '3:00 p.m.'),
                _tf('ceremonyNote', 'Nota', hint: 'Ceremonia religiosa'),
                _img('ceremonyImageUrl', 'Foto del lugar', weddingId),
              ]),
              _group('Recepción', [
                _tf('receptionTitle', 'Título', hint: 'Salón'),
                _tf('receptionVenue', 'Lugar', hint: 'Salón Real de La Piedad'),
                _tf('receptionAddress', 'Dirección', maxLines: 2),
                _tf('receptionMapUrl', 'Link de Google Maps', hint: 'https://maps.app.goo.gl/...'),
                _tf('receptionTime', 'Hora', hint: '5:00 p.m.'),
                _tf('receptionNote', 'Nota', hint: 'Recepción'),
                _img('receptionImageUrl', 'Foto del lugar', weddingId),
              ]),
              _group('Confirmación y vestimenta', [
                _tf('rsvpDeadline', 'Fecha límite para confirmar', hint: '15 de agosto de 2027'),
                _tf('dressCode', 'Código de vestimenta', hint: 'Formal'),
              ]),
              _group('Música', [
                _tf('spotifyPlaylistUrl', 'Link de la playlist de Spotify (opcional)',
                    hint: 'Cópialo con "Abrir en Spotify" desde la pantalla de Música'),
                _img('musicImageUrl', 'Foto decorativa (disco de vinilo, DJ, etc.)', weddingId),
              ]),
              _group('Regalos', [
                _tf('giftRegistryUrl', 'Link de tu lista de regalos'),
                _tf('giftMessage', 'Mensaje (opcional)', maxLines: 3),
                _img('giftImageUrl', 'Foto decorativa', weddingId),
              ]),
              _group('Pie de página', [
                _tf('instagramUrl', 'Instagram (opcional)', hint: 'https://instagram.com/...'),
              ]),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
