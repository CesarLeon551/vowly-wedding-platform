import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

/// Puente entre el Stream de Riverpod (authStateProvider) y el
/// Listenable que go_router necesita para refrescar el redirect
/// automáticamente cuando cambia la sesión.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;

      final loggingIn = state.matchedLocation == '/login';
      final isPublicRoute = state.matchedLocation.startsWith('/boda/');

      if (isLoading || isPublicRoute) return null;

      final loggedIn = user != null;
      if (!loggedIn) return loggingIn ? null : '/login';

      // Autenticado pero aún sin boda/rol asignado: lo dejamos donde
      // esté (más adelante aquí va la pantalla de "crear/unirme a boda").
      if (user.weddingId == null) return null;

      if (loggingIn) return '/w/${user.weddingId}/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/w/:weddingId/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Fase 5+: /w/:weddingId/budget, /savings, /guests, /vendors,
      // /tasks, /tables, /timeline, /music, /gallery, /documents, /stats
      //
      // Fase 9: /boda/:slug y /boda/:slug/rsvp (rutas públicas, sin auth)
    ],
  );
});
