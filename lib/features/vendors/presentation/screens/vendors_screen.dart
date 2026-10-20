import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/back_to_dashboard_button.dart';
import '../../../../domain/entities/vendor.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/vendors_providers.dart';
import 'add_vendor_screen.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  String? _categoryFilter;

  Color _statusColor(VendorStatus s) => switch (s) {
        VendorStatus.contratado => AppColors.sage,
        VendorStatus.cancelado => AppColors.danger,
        VendorStatus.cotizando => AppColors.gold,
      };

  String _statusLabel(VendorStatus s) => switch (s) {
        VendorStatus.contratado => 'Contratado',
        VendorStatus.cancelado => 'Cancelado',
        VendorStatus.cotizando => 'Cotizando',
      };

  @override
  Widget build(BuildContext context) {
    final weddingId = ref.watch(authStateProvider).valueOrNull?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final vendorsAsync = ref.watch(vendorsStreamProvider(weddingId));
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: BackToDashboardButton(weddingId: weddingId),
        title: const Text('Proveedores'),
      ),
      body: vendorsAsync.when(
        data: (vendors) {
          final filtered = _categoryFilter == null
              ? vendors
              : vendors.where((v) => v.category == _categoryFilter).toList();
          final categoriesInUse = vendors.map((v) => v.category).toSet().toList()..sort();

          return Column(
            children: [
              if (categoriesInUse.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: _categoryFilter == null,
                            onSelected: (_) => setState(() => _categoryFilter = null),
                          ),
                        ),
                        ...categoriesInUse.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: _categoryFilter == c,
                                onSelected: (_) => setState(() => _categoryFilter = c),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Agrega tu primer proveedor.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final v = filtered[i];
                          return Card(
                            child: ListTile(
                              title: Text(v.name),
                              subtitle: Text(
                                '${v.category}${v.company != null ? " · ${v.company}" : ""}\n'
                                '${currency.format(v.deposit)} pagado de ${currency.format(v.price)}',
                              ),
                              isThreeLine: true,
                              trailing: Chip(
                                label: Text(_statusLabel(v.status)),
                                backgroundColor: _statusColor(v.status).withOpacity(0.15),
                                labelStyle: TextStyle(color: _statusColor(v.status)),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddVendorScreen(weddingId: weddingId, existing: v),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddVendorScreen(weddingId: weddingId)),
        ),
        icon: const Icon(Icons.add_business),
        label: const Text('Proveedor'),
      ),
    );
  }
}
