import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/wedding_onboarding/presentation/screens/create_wedding_screen.dart';
import '../../features/wedding_onboarding/presentation/screens/invite_collaborator_screen.dart';
import '../../features/wedding_onboarding/presentation/screens/join_wedding_screen.dart';
import '../../features/wedding_onboarding/presentation/screens/welcome_screen.dart';

/// Puente entre el Stream de Riverpod (authStateProvider) y el
/// Listenable que go_router necesita para refrescar el redirect
/// automáticamente cuando cambia la sesión.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

const _authRoutes = ['/login', '/register'];
const _onboardingRoutes = ['/welcome', '/create-wedding', '/join-wedding'];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final loc = state.matchedLocation;

      final isPublicRoute = loc.startsWith('/boda/');
      if (isLoading || isPublicRoute) return null;

      final loggedIn = user != null;

      // Sin sesión: solo puede estar en login/registro.
      if (!loggedIn) {
        return _authRoutes.contains(loc) ? null : '/login';
      }

      // Con sesión pero sin boda todavía: solo puede estar en el flujo
      // de onboarding (welcome / crear boda / unirse con código).
      if (user.weddingId == null) {
        return _onboardingRoutes.contains(loc) ? null : '/welcome';
      }

      // Con sesión Y boda: si intenta ir a login/registro/onboarding,
      // lo mandamos derecho a su dashboard.
      if (_authRoutes.contains(loc) || _onboardingRoutes.contains(loc)) {
        return '/w/${user.weddingId}/dashboard';
      }

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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/create-wedding',
        builder: (context, state) => const CreateWeddingScreen(),
      ),
      GoRoute(
        path: '/join-wedding',
        builder: (context, state) => const JoinWeddingScreen(),
      ),
      GoRoute(
        path: '/w/:weddingId/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/w/:weddingId/invite',
        builder: (context, state) => const InviteCollaboratorScreen(),
      ),
      // Fase 5+: /w/:weddingId/budget, /savings, /guests, /vendors,
      // /tasks, /tables, /timeline, /music, /gallery, /documents, /stats
      //
      // Fase 9: /boda/:slug y /boda/:slug/rsvp (rutas públicas, sin auth)
    ],
  );
});
