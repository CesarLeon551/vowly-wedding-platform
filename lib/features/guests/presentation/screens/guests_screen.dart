import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/guest.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/guests_providers.dart';
import 'add_guest_screen.dart';

class GuestsScreen extends ConsumerStatefulWidget {
  const GuestsScreen({super.key});

  @override
  ConsumerState<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends ConsumerState<GuestsScreen> {
  RsvpStatus? _filter;

  Color _statusColor(RsvpStatus s) => switch (s) {
        RsvpStatus.confirmado => AppColors.sage,
        RsvpStatus.no_asistira => AppColors.danger,
        RsvpStatus.pendiente => AppColors.gold,
      };

  String _statusLabel(RsvpStatus s) => switch (s) {
        RsvpStatus.confirmado => 'Confirmado',
        RsvpStatus.no_asistira => 'No asistirá',
        RsvpStatus.pendiente => 'Pendiente',
      };

  @override
  Widget build(BuildContext context) {
    final weddingId = ref.watch(authStateProvider).valueOrNull?.weddingId;
    if (weddingId == null) return const SizedBox.shrink();

    final guestsAsync = ref.watch(guestsStreamProvider(weddingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Invitados')),
      body: guestsAsync.when(
        data: (guests) {
          final filtered = _filter == null ? guests : guests.where((g) => g.rsvpStatus == _filter).toList();
          final confirmed = guests.where((g) => g.rsvpStatus == RsvpStatus.confirmado).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Todos (${guests.length})'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    ...RsvpStatus.values.map((s) => ChoiceChip(
                          label: Text('${_statusLabel(s)} (${guests.where((g) => g.rsvpStatus == s).length})'),
                          selected: _filter == s,
                          onSelected: (_) => setState(() => _filter = s),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$confirmed confirmados de ${guests.length} invitados'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No hay invitados en este filtro.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final g = filtered[i];
                          return Card(
                            child: ListTile(
                              title: Text(g.fullName),
                              subtitle: Text([
                                if (g.group != null) g.group!,
                                if (g.companions.isNotEmpty) '+${g.companions.length} acompañante(s)',
                              ].join(' · ')),
                              trailing: Chip(
                                label: Text(_statusLabel(g.rsvpStatus)),
                                backgroundColor: _statusColor(g.rsvpStatus).withOpacity(0.15),
                                labelStyle: TextStyle(color: _statusColor(g.rsvpStatus)),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddGuestScreen(weddingId: weddingId, existing: g),
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
          MaterialPageRoute(builder: (_) => AddGuestScreen(weddingId: weddingId)),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Invitado'),
      ),
    );
  }
}
