import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/guest.dart';
import '../../../../domain/entities/wedding.dart';
import '../../../guests/application/guests_providers.dart';

class RsvpScreen extends ConsumerStatefulWidget {
  const RsvpScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends ConsumerState<RsvpScreen> {
  Wedding? _wedding;
  bool _loadingWedding = true;
  String? _weddingError;

  final _lastNameCtrl = TextEditingController();
  List<Guest> _results = [];
  bool _searching = false;
  Guest? _selected;

  @override
  void initState() {
    super.initState();
    _loadWedding();
  }

  Future<void> _loadWedding() async {
    try {
      final wedding = await ref.read(rsvpRepositoryProvider).findWeddingBySlug(widget.slug);
      setState(() {
        _wedding = wedding;
        _loadingWedding = false;
        if (wedding == null) _weddingError = 'No encontramos esta boda.';
      });
    } catch (e) {
      setState(() {
        _loadingWedding = false;
        _weddingError = 'Ocurrió un error. Intenta de nuevo.';
      });
    }
  }

  Future<void> _search() async {
    if (_lastNameCtrl.text.trim().isEmpty || _wedding == null) return;
    setState(() {
      _searching = true;
      _results = [];
      _selected = null;
    });
    final results = await ref
        .read(rsvpRepositoryProvider)
        .searchGuestsByLastName(_wedding!.id, _lastNameCtrl.text.trim());
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingWedding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_weddingError != null) {
      return Scaffold(body: Center(child: Text(_weddingError!)));
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _selected == null ? _buildSearch(context) : _buildRsvpForm(context, _selected!),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_wedding!.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Busca tu invitación por tu apellido', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(
          controller: _lastNameCtrl,
          decoration: const InputDecoration(labelText: 'Tu apellido'),
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _searching ? null : _search,
          child: _searching
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Buscar'),
        ),
        const SizedBox(height: 16),
        ..._results.map((g) => Card(
              child: ListTile(
                title: Text(g.fullName),
                subtitle: Text(g.group ?? ''),
                onTap: () => setState(() => _selected = g),
              ),
            )),
        if (!_searching && _results.isEmpty && _lastNameCtrl.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No encontramos invitaciones con ese apellido. Revisa la ortografía.'),
          ),
      ],
    );
  }

  Widget _buildRsvpForm(BuildContext context, Guest guest) {
    return _RsvpForm(
      weddingId: _wedding!.id,
      guest: guest,
      onBack: () => setState(() => _selected = null),
    );
  }
}

class _RsvpForm extends ConsumerStatefulWidget {
  const _RsvpForm({required this.weddingId, required this.guest, required this.onBack});

  final String weddingId;
  final Guest guest;
  final VoidCallback onBack;

  @override
  ConsumerState<_RsvpForm> createState() => _RsvpFormState();
}

class _RsvpFormState extends ConsumerState<_RsvpForm> {
  late RsvpStatus _status = widget.guest.rsvpStatus;
  late final List<TextEditingController> _companionCtrls = List.generate(
    widget.guest.allowedCompanions,
    (i) => TextEditingController(
      text: i < widget.guest.companions.length ? widget.guest.companions[i] : '',
    ),
  );
  late final _dietaryCtrl = TextEditingController(text: widget.guest.dietaryRestrictions);
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final companions = _companionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    await ref.read(rsvpRepositoryProvider).submitRsvp(
          widget.weddingId,
          widget.guest.copyWith(
            rsvpStatus: _status,
            companions: companions,
            dietaryRestrictions: _dietaryCtrl.text.trim().isEmpty ? null : _dietaryCtrl.text.trim(),
          ),
        );

    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.sage, size: 64),
          const SizedBox(height: 16),
          Text(
            _status == RsvpStatus.confirmado
                ? '¡Gracias por confirmar, ${widget.guest.firstName}!'
                : 'Gracias por avisarnos, ${widget.guest.firstName}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('No soy yo'),
        ),
        Text('Hola, ${widget.guest.fullName}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        SegmentedButton<RsvpStatus>(
          segments: const [
            ButtonSegment(value: RsvpStatus.confirmado, label: Text('Sí asistiré')),
            ButtonSegment(value: RsvpStatus.no_asistira, label: Text('No podré ir')),
          ],
          selected: {_status == RsvpStatus.pendiente ? RsvpStatus.confirmado : _status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
        if (_status == RsvpStatus.confirmado) ...[
          const SizedBox(height: 24),
          if (widget.guest.allowedCompanions > 0) ...[
            Text('Acompañantes (hasta ${widget.guest.allowedCompanions})',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._companionCtrls.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: c,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                  ),
                )),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _dietaryCtrl,
            decoration: const InputDecoration(labelText: 'Restricciones alimentarias (opcional)'),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar respuesta'),
        ),
      ],
    );
  }
}
