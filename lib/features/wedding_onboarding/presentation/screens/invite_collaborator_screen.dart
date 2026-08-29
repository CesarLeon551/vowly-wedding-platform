import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/roles.dart';
import '../../../../domain/entities/collaborator_invitation.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/wedding_providers.dart';

class InviteCollaboratorScreen extends ConsumerStatefulWidget {
  const InviteCollaboratorScreen({super.key});

  @override
  ConsumerState<InviteCollaboratorScreen> createState() => _InviteCollaboratorScreenState();
}

class _InviteCollaboratorScreenState extends ConsumerState<InviteCollaboratorScreen> {
  final _emailCtrl = TextEditingController();
  final Map<AppModule, bool> _selectedModules = {
    for (final m in AppModule.values) m: false,
  };
  bool _loading = false;
  CollaboratorInvitation? _lastInvite;

  String _moduleLabel(AppModule module) => switch (module) {
        AppModule.budget => 'Presupuesto',
        AppModule.savings => 'Ahorro',
        AppModule.guests => 'Invitados',
        AppModule.vendors => 'Proveedores',
        AppModule.tasks => 'Tareas',
        AppModule.tables => 'Mesas',
        AppModule.timeline => 'Cronograma',
        AppModule.music => 'Música',
        AppModule.gallery => 'Galería',
        AppModule.documents => 'Documentos',
      };

  Future<void> _submit(String weddingId) async {
    setState(() => _loading = true);
    try {
      final invite = await ref.read(weddingRepositoryProvider).inviteCollaborator(
            weddingId: weddingId,
            invitedEmail: _emailCtrl.text.trim(),
            permissions: _selectedModules,
          );
      setState(() => _lastInvite = invite);
      _emailCtrl.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final weddingId = user?.weddingId;

    if (weddingId == null) {
      return const Scaffold(body: Center(child: Text('Sin boda asociada.')));
    }

    final invitationsAsync = ref.watch(_invitationsStreamProvider(weddingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Invitar colaboradores')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Correo del colaborador'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Text('Módulos a los que tendrá acceso', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: AppModule.values.map((module) {
              return FilterChip(
                label: Text(_moduleLabel(module)),
                selected: _selectedModules[module] ?? false,
                onSelected: (v) => setState(() => _selectedModules[module] = v),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading || _emailCtrl.text.trim().isEmpty
                ? null
                : () => _submit(weddingId),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Generar invitación'),
          ),
          if (_lastInvite != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Código para ${_lastInvite!.invitedEmail}: ${_lastInvite!.code}\n'
                  'Compártelo por WhatsApp o el medio que prefieras — el colaborador '
                  'lo captura en "Tengo un código de invitación".',
                ),
              ),
            ),
          ],
          const Divider(height: 48),
          Text('Invitaciones enviadas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          invitationsAsync.when(
            data: (invites) => Column(
              children: invites.map((inv) {
                return ListTile(
                  title: Text(inv.invitedEmail),
                  subtitle: Text('Código: ${inv.code}'),
                  trailing: Text(switch (inv.status) {
                    InvitationStatus.pending => 'Pendiente',
                    InvitationStatus.accepted => 'Aceptada',
                    InvitationStatus.revoked => 'Revocada',
                  }),
                );
              }).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Text('No se pudieron cargar las invitaciones.'),
          ),
        ],
      ),
    );
  }
}

final _invitationsStreamProvider = StreamProvider.family((ref, String weddingId) {
  return ref.watch(weddingRepositoryProvider).watchInvitations(weddingId);
});
