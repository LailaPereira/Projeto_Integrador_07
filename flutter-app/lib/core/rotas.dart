import 'package:go_router/go_router.dart';
import '../screens/tela_carregamento.dart';
import '../screens/tela_entrar.dart';
import '../screens/tela_registrar.dart';
import '../screens/tela_inicio.dart';
import '../screens/tela_perfil.dart';
import '../screens/tela_permissoes_backend.dart';

GoRouter rotasApp() {
  return GoRouter(
    initialLocation: '/carregamento',
    routes: [
      GoRoute(
        path: '/carregamento',
        builder: (context, state) => const TelaCarregamento(),
      ),
      GoRoute(
        path: '/entrar',
        builder: (context, state) => const TelaEntrar(),
      ),
      GoRoute(
        path: '/registrar',
        builder: (context, state) => const TelaRegistrar(),
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, state) => const TelaInicio(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const TelaPerfil(),
      ),
      GoRoute(
        path: '/permissoes-backend',
        builder: (context, state) => const TelaPermissoesBackend(),
      ),
    ],
  );
}
