import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../guests/application/guests_providers.dart';
import '../../../../domain/entities/guest.dart';
import '../../../../app/theme/back_to_dashboard_button.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key, required this.weddingId});
  final String weddingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: BackToDashboardButton(weddingId: weddingId),
          title: const Text('Mesas y cronograma'),
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.table_restaurant), text: 'Mesas'), Tab(icon: Icon(Icons.schedule), text: 'Cronograma')]),
        ),
        body: TabBarView(children: [_TablesView(weddingId: weddingId), _TimelineView(weddingId: weddingId)]),
      ),
    );
  }
}

class _TablesView extends ConsumerStatefulWidget {
  const _TablesView({required this.weddingId});
  final String weddingId;
  @override
  ConsumerState<_TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends ConsumerState<_TablesView> {
  static const wine = Color(0xFF772B43);
  static const cream = Color(0xFFF9F3EF);
  static const gold = Color(0xFFC7A47A);
  String query = '';
  String filter = 'Sin mesa';
  String? selectedGuest;
  String? selectedTable;
  bool busy = false;

  int places(Guest g) => 1 + g.companions.length;
  int occupied(List<Guest> people, String id) => people
      .where((g) => g.tableId == id && g.rsvpStatus == RsvpStatus.confirmado)
      .fold(0, (int total, g) => total + places(g));

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final tableRef = db.collection('weddings').doc(widget.weddingId).collection('tables');
    final guestState = ref.watch(guestsStreamProvider(widget.weddingId));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tableRef.snapshots(),
      builder: (context, tableSnap) {
        if (tableSnap.hasError) return Center(child: Text('Error de mesas: ${tableSnap.error}'));
        if (!tableSnap.hasData) return const Center(child: CircularProgressIndicator());
        return guestState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error de invitados: $e')),
          data: (people) {
            final tables = tableSnap.data!.docs.toList()..sort((a,b) =>
                (a.data()['name'] ?? '').toString().compareTo((b.data()['name'] ?? '').toString()));
            final confirmed = people.where((g) => g.rsvpStatus == RsvpStatus.confirmado).toList();
            final visible = confirmed.where((g) {
              final matches = g.fullName.toLowerCase().contains(query.toLowerCase());
              return matches && (filter == 'Todos' || (filter == 'Sin mesa' ? g.tableId == null : g.tableId != null));
            }).toList();
            final totalSeats = confirmed.fold(0, (int n,g) => n + places(g));
            final assigned = confirmed.where((g) => g.tableId != null).fold(0, (int n,g) => n + places(g));
            final capacity = tables.fold(0, (int n,t) => n + ((t.data()['capacity'] as num?)?.toInt() ?? 0));
            return Container(
              color: cream,
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final guestPanel = _guestPanel(visible, confirmed);
                final floor = _floor(context, db, tableRef, tables, confirmed);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 24 : 12),
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 12, children: [
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Distribución de mesas', style: TextStyle(fontFamily: 'Georgia', fontSize: 30, color: wine, fontWeight: FontWeight.bold)),
                          Text('Organiza a tus invitados y prepara el plano de recepción', style: TextStyle(color: Color(0xFF937F7B))),
                        ]),
                        FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: wine), onPressed: () => _editTable(context, tableRef), icon: const Icon(Icons.add), label: const Text('Crear mesa')),
                      ]),
                      const SizedBox(height: 18),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        _stat('Lugares confirmados', '$totalSeats', Icons.people_alt_outlined),
                        _stat('Lugares asignados', '$assigned', Icons.check_circle_outline),
                        _stat('Lugares disponibles', '${capacity - assigned}', Icons.event_seat_outlined),
                        _stat('Mesas', '${tables.length}', Icons.table_restaurant_outlined),
                      ]),
                      const SizedBox(height: 20),
                      if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 330, child: guestPanel),
                        const SizedBox(width: 16),
                        Expanded(child: floor),
                      ]) else Column(children: [guestPanel, const SizedBox(height: 14), floor]),
                      const SizedBox(height: 14),
                      const Text('Arrastra a un invitado hasta una mesa. En celular también puedes seleccionarlo y tocar una mesa.', style: TextStyle(color: Color(0xFF8D7973), fontSize: 12)),
                    ]),
                  )),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _stat(String label, String value, IconData icon) => Container(
    width: 185, padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDFD8))),
    child: Row(children: [Icon(icon, color: wine), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 22, color: wine, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF907E77))),
    ]))]),
  );

  Widget _guestPanel(List<Guest> visible, List<Guest> all) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _card(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Invitados', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: wine)),
      const SizedBox(height: 4),
      Text('${all.length} confirmados · ${all.where((g) => g.tableId == null).length} sin mesa', style: const TextStyle(color: Color(0xFF947E79), fontSize: 12)),
      const SizedBox(height: 12),
      TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(
        hintText: 'Buscar invitado...', prefixIcon: const Icon(Icons.search), isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 12),
      Wrap(spacing: 5, children: ['Sin mesa', 'Todos', 'Asignados'].map((v) => ChoiceChip(
        label: Text(v), selected: filter == v,
        selectedColor: const Color(0xFFF0DDE3),
        onSelected: (_) => setState(() => filter = v),
      )).toList()),
      const SizedBox(height: 10),
      if (visible.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No hay invitados en este filtro.')),
      for (final g in visible) Padding(padding: const EdgeInsets.only(bottom: 7), child: Draggable<String>(
        data: g.id,
        feedback: Material(color: Colors.transparent, child: SizedBox(width: 245, child: _guestTile(g, dragging: true))),
        childWhenDragging: Opacity(opacity: .35, child: _guestTile(g)),
        child: InkWell(onTap: () => setState(() => selectedGuest = selectedGuest == g.id ? null : g.id), child: _guestTile(g)),
      )),
    ]),
  );

  Widget _guestTile(Guest g, {bool dragging = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: selectedGuest == g.id || dragging ? const Color(0xFFF1DEE3) : const Color(0xFFFCF8F5),
      borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedGuest == g.id ? wine : const Color(0xFFF0E3DE))),
    child: Row(children: [
      const Icon(Icons.drag_indicator, size: 17, color: Color(0xFFB59E96)),
      const SizedBox(width: 6),
      CircleAvatar(radius: 17, backgroundColor: const Color(0xFFE4BFC6), child: Text(g.fullName.isEmpty ? '?' : g.fullName[0].toUpperCase(), style: const TextStyle(color: wine))),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wine, fontWeight: FontWeight.w600, fontSize: 13)),
        Text('${places(g)} lugar(es) · ${g.tableId == null ? 'Sin mesa' : 'Asignado'}', style: const TextStyle(color: Color(0xFF937F7B), fontSize: 11)),
      ])),
      if (selectedGuest == g.id) const Icon(Icons.check_circle, size: 18, color: wine),
    ]),
  );

  Widget _floor(BuildContext context, FirebaseFirestore db, CollectionReference<Map<String,dynamic>> tableRef,
      List<QueryDocumentSnapshot<Map<String,dynamic>>> tables, List<Guest> people) {
    return Container(padding: const EdgeInsets.all(16), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Plano de recepción', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, color: wine, fontWeight: FontWeight.bold))),
        Text('${tables.length} mesas', style: const TextStyle(color: Color(0xFF9C8078))),
      ]),
      const SizedBox(height: 5),
      const Text('Suelta cada invitado en la mesa correspondiente', style: TextStyle(color: Color(0xFF9C8078), fontSize: 12)),
      const SizedBox(height: 16),
      if (tables.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Crea tu primera mesa para empezar.'))),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 750 ? 3 : c.maxWidth >= 440 ? 2 : 1;
        final itemWidth = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: tables.map((doc) {
          final data = doc.data();
          final cap = (data['capacity'] as num?)?.toInt() ?? 0;
          final seats = occupied(people, doc.id);
          final seated = people.where((g) => g.tableId == doc.id).toList();
          return SizedBox(width: itemWidth, child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => !busy && people.any((g) => g.id == details.data),
            onAcceptWithDetails: (details) => _assign(db, people, details.data, doc.id),
            builder: (context, candidates, rejects) => InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () { setState(() => selectedTable = doc.id); if (selectedGuest != null) _assign(db, people, selectedGuest!, doc.id); },
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                color: candidates.isNotEmpty ? const Color(0xFFF5E5E9) : const Color(0xFFFFFCFA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: candidates.isNotEmpty || selectedTable == doc.id ? wine : const Color(0xFFEBDDD5), width: candidates.isNotEmpty ? 2 : 1),
              ), child: Column(children: [
                Row(children: [Expanded(child: Text('${data['name'] ?? 'Mesa'}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: wine, fontWeight: FontWeight.w700))),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: wine), tooltip: 'Editar mesa',
                    onPressed: () => _editTable(context, tableRef, doc: doc))]),
                SizedBox(height: 150, child: CustomPaint(painter: _RoundTablePainter(capacity: cap, occupied: seats), child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('MESA', style: TextStyle(color: Color(0xFF9C8078), fontSize: 10)),
                    Text('${tables.indexOf(doc) + 1}', style: const TextStyle(color: wine, fontSize: 27, fontWeight: FontWeight.bold)),
                  ])))),
                Text('$seats / $cap lugares', style: const TextStyle(color: wine, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(
                  value: cap <= 0 ? 0 : (seats / cap).clamp(0.0, 1.0), minHeight: 5,
                  backgroundColor: const Color(0xFFF1E7E1), valueColor: const AlwaysStoppedAnimation(wine))),
                const SizedBox(height: 8),
                for (final g in seated) Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                  Expanded(child: Text('${g.fullName} (${places(g)})', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF74485A)))),
                  IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    tooltip: 'Quitar de mesa', icon: const Icon(Icons.close, size: 15),
                    onPressed: () => _assign(db, people, g.id, null)),
                ])),
                if (candidates.isNotEmpty) const Text('Soltar aquí', style: TextStyle(color: wine, fontWeight: FontWeight.bold)),
              ])),
            ),
          ));
        }).toList());
      }),
    ]));
  }

  BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEADDD5)), boxShadow: const [BoxShadow(color: Color(0x0C772B43), blurRadius: 18, offset: Offset(0, 6))]);

  Future<void> _assign(FirebaseFirestore db, List<Guest> people, String guestId, String? tableId) async {
    if (busy) return;
    final matches = people.where((g) => g.id == guestId).toList();
    if (matches.isEmpty) return;
    final guest = matches.first;
    setState(() => busy = true);
    try {
      final base = db.collection('weddings').doc(widget.weddingId);
      final guestRef = base.collection('guests').doc(guestId);
      await db.runTransaction((tx) async {
        final current = await tx.get(guestRef);
        if (!current.exists) throw StateError('El invitado ya no existe');
        if (tableId != null) {
          final table = await tx.get(base.collection('tables').doc(tableId));
          if (!table.exists) throw StateError('La mesa ya no existe');
          final cap = (table.data()?['capacity'] as num?)?.toInt() ?? 0;
          final used = people.where((g) => g.tableId == tableId && g.id != guestId && g.rsvpStatus == RsvpStatus.confirmado)
              .fold(0, (int n,g) => n + places(g));
          if (used + places(guest) > cap) throw StateError('La mesa no tiene lugares suficientes');
          if (current.data()?['rsvpStatus'] != 'confirmado') throw StateError('El invitado no está confirmado');
        }
        tx.update(guestRef, {'tableId': tableId});
      });
      if (mounted) setState(() => selectedGuest = null);
    } catch (e) {
      if (mounted) _notice(context, 'No se pudo asignar: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editTable(BuildContext context, CollectionReference<Map<String, dynamic>> tables,
      {QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final name = TextEditingController(text: doc?.data()['name']?.toString() ?? '');
    final capacity = TextEditingController(text: doc?.data()['capacity']?.toString() ?? '8');
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(doc == null ? 'Crear mesa' : 'Editar mesa'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacidad')),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))],
    ));
    if (ok != true) return;
    final n = int.tryParse(capacity.text);
    if (name.text.trim().isEmpty || n == null || n <= 0) {
      if (context.mounted) _notice(context, 'Escribe un nombre y capacidad válida');
      return;
    }
    try {
      if (doc == null) { await tables.add({'name': name.text.trim(), 'capacity': n}); }
      else { await doc.reference.update({'name': name.text.trim(), 'capacity': n}); }
    } catch (e) { if (context.mounted) _notice(context, 'No se pudo guardar: $e'); }
  }
}

class _RoundTablePainter extends CustomPainter {
  const _RoundTablePainter({required this.capacity, required this.occupied});
  final int capacity;
  final int occupied;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height * .30;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF5E9E2));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFC7A47A)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final count = capacity.clamp(0, 24);
    for (var i = 0; i < count; i++) {
      final angle = 2 * 3.141592653589793 * i / count - 3.141592653589793 / 2;
      final r = radius + 12;
      final seat = center + Offset(r * _cos(angle), r * _sin(angle));
      canvas.drawCircle(seat, count > 16 ? 5 : 7, Paint()..color = i < occupied ? const Color(0xFF772B43) : const Color(0xFFE3CEC1));
      canvas.drawCircle(seat, count > 16 ? 5 : 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.4);
    }
  }
  double _cos(double angle) => math.cos(angle);
  double _sin(double angle) => math.sin(angle);
  @override
  bool shouldRepaint(covariant _RoundTablePainter old) => old.capacity != capacity || old.occupied != occupied;
}

class _TimelineView extends ConsumerWidget {
  const _TimelineView({required this.weddingId});
  final String weddingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(firestoreProvider).collection('weddings').doc(weddingId).collection('timelineEvents');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: events.orderBy('startAt').snapshots(), builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Agregar evento'), onPressed: () => _editEvent(context, events)),
        const SizedBox(height: 12),
        if (snapshot.data!.docs.isEmpty) const Text('Todavía no hay eventos en el cronograma.'),
        for (final doc in snapshot.data!.docs) Card(child: ListTile(
          leading: const Icon(Icons.event),
          title: Text(doc.data()['title']?.toString() ?? 'Evento'),
          subtitle: Text('${_formatTime(doc.data()['startAt'])} · ${doc.data()['durationMinutes'] ?? 0} min\n${doc.data()['location'] ?? ''} · ${doc.data()['responsible'] ?? ''}\n${doc.data()['notes'] ?? ''}'),
          isThreeLine: true,
          onTap: () => _editEvent(context, events, doc: doc),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Eliminar evento', onPressed: () async { final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('¿Eliminar evento?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar'))])); if (yes == true) { try { await doc.reference.delete(); } catch (e) { if (context.mounted) _notice(context, 'Error: $e'); } } }),
        )),
      ]);
    });
  }

  static String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Sin hora';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editEvent(BuildContext context, CollectionReference<Map<String, dynamic>> events, {QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final d = doc?.data() ?? <String, dynamic>{};
    final title = TextEditingController(text: d['title']?.toString() ?? '');
    final location = TextEditingController(text: d['location']?.toString() ?? '');
    final responsible = TextEditingController(text: d['responsible']?.toString() ?? '');
    final notes = TextEditingController(text: d['notes']?.toString() ?? '');
    final duration = TextEditingController(text: (d['durationMinutes'] ?? 60).toString());
    var start = (d['startAt'] as Timestamp?)?.toDate() ?? DateTime(2027, 8, 28, 17);
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setLocal) => AlertDialog(title: Text(doc == null ? 'Nuevo evento' : 'Editar evento'), content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Evento')),
      TextButton.icon(icon: const Icon(Icons.calendar_month), label: Text(_formatTime(Timestamp.fromDate(start))), onPressed: () async { final day = await showDatePicker(context: c, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: start); if (day == null || !c.mounted) return; final time = await showTimePicker(context: c, initialTime: TimeOfDay.fromDateTime(start)); if (time != null) setLocal(() => start = DateTime(day.year, day.month, day.day, time.hour, time.minute)); }),
      TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duración en minutos')),
      TextField(controller: location, decoration: const InputDecoration(labelText: 'Lugar')),
      TextField(controller: responsible, decoration: const InputDecoration(labelText: 'Responsable')),
      TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notas')),
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))])));
    if (ok != true) return;
    final minutes = int.tryParse(duration.text);
    if (title.text.trim().isEmpty || minutes == null || minutes <= 0) { if (context.mounted) _notice(context, 'Completa evento y duración válida'); return; }
    final data = {'title': title.text.trim(), 'startAt': Timestamp.fromDate(start), 'durationMinutes': minutes, 'location': location.text.trim(), 'responsible': responsible.text.trim(), 'notes': notes.text.trim()};
    try { if (doc == null) { await events.add(data); } else { await doc.reference.update(data); } } catch (e) { if (context.mounted) _notice(context, 'No se pudo guardar: $e'); }
  }
}

void _notice(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
