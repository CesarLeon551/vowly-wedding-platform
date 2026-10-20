import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/providers/storage_providers.dart';
import '../../../../domain/entities/vendor.dart';
import '../../application/vendors_providers.dart';

class AddVendorScreen extends ConsumerStatefulWidget {
  const AddVendorScreen({super.key, required this.weddingId, this.existing});

  final String weddingId;
  final Vendor? existing;

  @override
  ConsumerState<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends ConsumerState<AddVendorScreen> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _companyCtrl = TextEditingController(text: widget.existing?.company);
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone);
  late final _whatsappCtrl = TextEditingController(text: widget.existing?.whatsapp);
  late final _emailCtrl = TextEditingController(text: widget.existing?.email);
  late final _priceCtrl =
      TextEditingController(text: widget.existing?.price.toStringAsFixed(0) ?? '');
  late final _depositCtrl =
      TextEditingController(text: widget.existing?.deposit.toStringAsFixed(0) ?? '0');
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes);

  late String _category = widget.existing?.category ?? kVendorCategories.first;
  late VendorStatus _status = widget.existing?.status ?? VendorStatus.cotizando;

  String? _contractUrl;
  String? _quoteUrl;
  late List<String> _receiptUrls = List.of(widget.existing?.receiptUrls ?? []);

  bool _loading = false;
  String? _uploadingLabel;

  @override
  void initState() {
    super.initState();
    _contractUrl = widget.existing?.contractUrl;
    _quoteUrl = widget.existing?.quoteUrl;
  }

  /// Abre el selector de archivos del navegador y sube el resultado a R2
  /// vía el Worker (StorageRepository de Fase 2.1).
  Future<String?> _pickAndUpload(String label, String folder) async {
    final input = html.FileUploadInputElement()..accept = '.pdf,.jpg,.jpeg,.png';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return null;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = (reader.result as Uint8List).toList();

    setState(() => _uploadingLabel = label);
    try {
      final path =
          'weddings/${widget.weddingId}/vendors/$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      return await ref.read(storageRepositoryProvider).uploadFile(
            path: path,
            bytes: bytes,
            contentType: file.type.isNotEmpty ? file.type : 'application/octet-stream',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo subir el archivo: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingLabel = null);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);
    await ref.read(vendorRepositoryProvider).upsertVendor(
          widget.weddingId,
          Vendor(
            id: widget.existing?.id ?? '',
            category: _category,
            name: _nameCtrl.text.trim(),
            company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
            price: double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
            deposit: double.tryParse(_depositCtrl.text.replaceAll(',', '')) ?? 0,
            status: _status,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            contractUrl: _contractUrl,
            quoteUrl: _quoteUrl,
            receiptUrls: _receiptUrls,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(vendorRepositoryProvider).deleteVendor(widget.weddingId, widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nuevo proveedor' : 'Editar proveedor'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: kVendorCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 16),
          TextField(
            controller: _companyCtrl,
            decoration: const InputDecoration(labelText: 'Empresa (opcional)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(labelText: 'WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Precio total'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _depositCtrl,
                  decoration: const InputDecoration(labelText: 'Anticipo pagado'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VendorStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: VendorStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notas'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Text('Documentos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _DocRow(
            label: 'Cotización',
            url: _quoteUrl,
            uploading: _uploadingLabel == 'Cotización',
            onUpload: () async {
              final url = await _pickAndUpload('Cotización', 'quotes');
              if (url != null) setState(() => _quoteUrl = url);
            },
          ),
          _DocRow(
            label: 'Contrato',
            url: _contractUrl,
            uploading: _uploadingLabel == 'Contrato',
            onUpload: () async {
              final url = await _pickAndUpload('Contrato', 'contracts');
              if (url != null) setState(() => _contractUrl = url);
            },
          ),
          const SizedBox(height: 8),
          Text('Comprobantes de pago', style: Theme.of(context).textTheme.titleSmall),
          ..._receiptUrls.asMap().entries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long),
                title: Text('Comprobante ${entry.key + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => setState(() => _receiptUrls.removeAt(entry.key)),
                ),
              )),
          TextButton.icon(
            icon: _uploadingLabel == 'Comprobante'
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
            label: const Text('Agregar comprobante'),
            onPressed: () async {
              final url = await _pickAndUpload('Comprobante', 'receipts');
              if (url != null) setState(() => _receiptUrls = [..._receiptUrls, url]);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.url,
    required this.uploading,
    required this.onUpload,
  });

  final String label;
  final String? url;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(url != null ? Icons.check_circle : Icons.upload_file,
          color: url != null ? AppColors.sage : null),
      title: Text(label),
      subtitle: Text(url != null ? 'Subido' : 'Sin subir'),
      trailing: uploading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(onPressed: onUpload, child: Text(url != null ? 'Reemplazar' : 'Subir')),
    );
  }
}
