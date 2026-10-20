import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/guest.dart';
import '../../application/public_page_providers.dart';
import 'invitation_style.dart';

/// Confirmación de asistencia. Dos estados: formulario (si aún no ha
/// respondido o toca "Cambiar mi respuesta") y resumen de lo que ya
/// respondió.
class RsvpSection extends ConsumerStatefulWidget {
  const RsvpSection({super.key, required this.weddingId, required this.guest});

  final String weddingId;
  final Guest guest;

  @override
  ConsumerState<RsvpSection> createState() => _RsvpSectionState();
}

class _RsvpSectionState extends ConsumerState<RsvpSection> {
  late Guest _current;
  late bool _editing;
  RsvpStatus? _choice;
  late final List<TextEditingController> _companionCtrls;
  late final TextEditingController _dietaryCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _current = widget.guest;
    _editing = _current.rsvpStatus == RsvpStatus.pendiente;
    _choice = _editing ? null : _current.rsvpStatus;
    _companionCtrls = List.generate(
      _current.allowedCompanions,
      (i) => TextEditingController(
        text: i < _current.companions.length ? _current.companions[i] : '',
      ),
    );
    _dietaryCtrl = TextEditingController(text: _current.dietaryRestrictions ?? '');
  }

  @override
  void dispose() {
    for (final c in _companionCtrls) {
      c.dispose();
    }
    _dietaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final choice = _choice;
    if (choice == null) return;

    setState(() => _submitting = true);

    final confirmed = choice == RsvpStatus.confirmado;
    final companions = confirmed
        ? _companionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final dietary = confirmed && _dietaryCtrl.text.trim().isNotEmpty
        ? _dietaryCtrl.text.trim()
        : null;

    // Se arma el Guest completo (y no con copyWith) para poder limpiar
    // las restricciones alimentarias cuando el invitado borra el campo.
    final updated = Guest(
      id: _current.id,
      firstName: _current.firstName,
      lastName: _current.lastName,
      phone: _current.phone,
      email: _current.email,
      group: _current.group,
      invitedBy: _current.invitedBy,
      allowedCompanions: _current.allowedCompanions,
      companions: companions,
      isAdult: _current.isAdult,
      rsvpStatus: choice,
      dietaryRestrictions: dietary,
      tableId: _current.tableId,
      notes: _current.notes,
    );

    try {
      await ref.read(rsvpRepositoryProvider).submitRsvp(widget.weddingId, updated);
      if (!mounted) return;
      setState(() {
        _current = updated;
        _editing = false;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar tu respuesta. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: InvitationStyle.rose.withOpacity(0.5)),
        boxShadow: InvitationStyle.softShadow,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _editing ? _buildForm(context) : _buildDone(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final confirmed = _choice == RsvpStatus.confirmado;
    final n = _current.allowedCompanions;

    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Nos acompañas, ${_current.firstName}?',
          textAlign: TextAlign.center,
          style: InvitationStyle.script(38),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _ChoiceTile(
                icon: Icons.celebration_outlined,
                label: 'Ahí estaré',
                selected: _choice == RsvpStatus.confirmado,
                onTap: () => setState(() => _choice = RsvpStatus.confirmado),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceTile(
                icon: Icons.sentiment_dissatisfied_outlined,
                label: 'No podré asistir',
                selected: _choice == RsvpStatus.no_asistira,
                onTap: () => setState(() => _choice = RsvpStatus.no_asistira),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: confirmed
              ? Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (n > 0) ...[
                        Text(
                          'Tu invitación incluye hasta $n ${n == 1 ? 'acompañante' : 'acompañantes'}',
                          style: InvitationStyle.body(size: 14),
                        ),
                        const SizedBox(height: 12),
                        ..._companionCtrls.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextField(
                                  controller: e.value,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(labelText: 'Acompañante ${e.key + 1}'),
                                ),
                              ),
                            ),
                      ],
                      TextField(
                        controller: _dietaryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Restricciones alimentarias (opcional)',
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (_choice == null || _submitting) ? null : _submit,
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enviar respuesta'),
        ),
        if (_current.rsvpStatus != RsvpStatus.pendiente)
          TextButton(
            onPressed: () => setState(() {
              _editing = false;
              _choice = _current.rsvpStatus;
            }),
            child: const Text('Cancelar'),
          ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    final confirmed = _current.rsvpStatus == RsvpStatus.confirmado;
    final accent = confirmed ? AppColors.sage : InvitationStyle.rose;
    final dietary = _current.dietaryRestrictions;

    return Column(
      key: const ValueKey('done'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.18)),
          child: Icon(
            confirmed ? Icons.check_rounded : Icons.favorite_border,
            color: accent,
            size: 32,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          confirmed
              ? '¡Qué alegría, ${_current.firstName}!'
              : 'Gracias por avisarnos, ${_current.firstName}',
          textAlign: TextAlign.center,
          style: InvitationStyle.script(40),
        ),
        const SizedBox(height: 8),
        Text(
          confirmed
              ? 'Tu asistencia quedó confirmada. Te esperamos con mucho cariño.'
              : 'Lamentamos que no puedas acompañarnos. Te vamos a extrañar.',
          textAlign: TextAlign.center,
          style: InvitationStyle.body(),
        ),
        if (confirmed && _current.companions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Acompañantes: ${_current.companions.join(', ')}',
            textAlign: TextAlign.center,
            style: InvitationStyle.body(size: 14),
          ),
        ],
        if (confirmed && dietary != null && dietary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Restricciones: $dietary',
            textAlign: TextAlign.center,
            style: InvitationStyle.body(size: 14),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _editing = true;
            _choice = _current.rsvpStatus;
          }),
          child: const Text('Cambiar mi respuesta'),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? InvitationStyle.burgundy.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? InvitationStyle.burgundy : InvitationStyle.rose,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? InvitationStyle.burgundy : InvitationStyle.ink.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: InvitationStyle.body(
                size: 15,
                color: selected ? InvitationStyle.ink : InvitationStyle.ink.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
