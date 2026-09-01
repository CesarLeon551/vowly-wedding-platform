import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/dashboard_stats.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/dashboard_providers.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final weddingId = user?.weddingId;

    if (weddingId == null) {
      return const Scaffold(body: Center(child: Text('Sin boda asociada.')));
    }

    final statsAsync = ref.watch(dashboardStatsProvider(weddingId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.displayName ?? ''}'),
        actions: [
          if (user?.isCouple ?? false)
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: 'Invitar colaboradores',
              onPressed: () => context.go('/w/$weddingId/invite'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _DashboardBody(stats: stats, weddingId: weddingId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo cargar el dashboard.\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats, required this.weddingId});

  final DashboardStats stats;
  final String weddingId;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cuenta regresiva
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.terracotta,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '${stats.daysRemaining}',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Text('días para la boda', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Accesos rápidos a los módulos ya construidos
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Presupuesto'),
                onPressed: () => context.go('/w/$weddingId/budget'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Ahorro'),
                onPressed: () => context.go('/w/$weddingId/savings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.people_outline),
          label: const Text('Invitados'),
          onPressed: () => context.go('/w/$weddingId/guests'),
        ),
        const SizedBox(height: 16),

        // Alertas
        if (stats.alerts.isNotEmpty) ...[
          ...stats.alerts.map((a) => Card(
                color: AppColors.blush.withOpacity(0.4),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.terracotta),
                  title: Text(a),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Finanzas
        DashboardSectionCard(
          title: 'Finanzas',
          child: Row(
            children: [
              StatTile(label: 'Presupuesto', value: currency.format(stats.plannedBudget)),
              const SizedBox(width: 8),
              StatTile(label: 'Gastado', value: currency.format(stats.spent)),
              const SizedBox(width: 8),
              StatTile(label: 'Ahorrado', value: currency.format(stats.saved)),
              const SizedBox(width: 8),
              StatTile(label: 'Pendiente', value: currency.format(stats.pending)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Invitados
        DashboardSectionCard(
          title: 'Invitados',
          child: Row(
            children: [
              StatTile(label: 'Total', value: '${stats.totalGuests}'),
              const SizedBox(width: 8),
              StatTile(
                label: 'Confirmados',
                value: '${stats.confirmedGuests}',
                color: AppColors.sage,
              ),
              const SizedBox(width: 8),
              StatTile(label: 'Pendientes', value: '${stats.pendingGuests}'),
              const SizedBox(width: 8),
              StatTile(
                label: 'No asistirán',
                value: '${stats.notAttendingGuests}',
                color: AppColors.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Organización
        DashboardSectionCard(
          title: 'Organización',
          child: Row(
            children: [
              StatTile(
                label: 'Tareas completadas',
                value: '${stats.tasksCompleted}',
                color: AppColors.sage,
              ),
              const SizedBox(width: 8),
              StatTile(label: 'Tareas pendientes', value: '${stats.tasksPending}'),
              const SizedBox(width: 8),
              StatTile(label: 'Proveedores contratados', value: '${stats.vendorsHired}'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Próximos eventos (tareas con vencimiento en 14 días)
        DashboardSectionCard(
          title: 'Próximos pendientes',
          child: stats.upcomingTasks.isEmpty
              ? const Text('Nada por vencer en los próximos 14 días.')
              : Column(
                  children: stats.upcomingTasks
                      .map((t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_outlined),
                            title: Text(t.name),
                            trailing: Text(DateFormat.MMMd('es_MX').format(t.dueDate)),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
