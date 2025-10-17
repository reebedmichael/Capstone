import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/admin_access_guard.dart';
import 'package:capstone_admin/features/auth/presentation/teken_in_page.dart';
import 'package:capstone_admin/features/auth/presentation/registreer_admin_page.dart';
import 'package:capstone_admin/features/auth/presentation/wag_vir_goedkeuring_page.dart';
import 'package:capstone_admin/features/auth/presentation/wagwoord_herstel_page.dart';
import 'package:capstone_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:capstone_admin/features/spyskaart/presentation/spyskaart_bestuur_page.dart';
import 'package:capstone_admin/features/spyskaart/presentation/week_spyskaart_page.dart';
import 'package:capstone_admin/features/templates/presentation/kositem_templaat_page.dart';
import 'package:capstone_admin/features/templates/presentation/week_templaat_page.dart';
import 'package:capstone_admin/features/bestellings/presentation/bestelling_bestuur_page.dart';
import 'package:capstone_admin/features/gebruikers/presentation/gebruikers_bestuur_page.dart';
import 'package:capstone_admin/features/toelae/presentation/toelae_main_page.dart';
import 'package:capstone_admin/features/toelae/presentation/toelae_bestuur_page.dart';
import 'package:capstone_admin/features/toelae/presentation/gebruiker_tipes_toelae_page.dart';
import 'package:capstone_admin/features/toelae/presentation/transaksie_geskiedenis_page.dart';
import 'package:capstone_admin/features/kennisgewings/presentation/kennisgewings_page.dart';
import 'package:capstone_admin/features/verslae/presentation/verslae_page.dart';
import 'package:capstone_admin/features/instellings/presentation/instellings_page.dart';
import 'package:capstone_admin/features/hulp/presentation/hulp_page.dart';
import 'package:capstone_admin/features/profiel/presentation/profiel_page.dart';
import '../../pages/db_test_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/teken_in',
    routes: [
      GoRoute(
        path: '/teken_in',
        name: 'teken_in',
        pageBuilder: (context, state) => _noTransitionPage(const TekenInPage(), state),
      ),
      GoRoute(
        path: '/registreer_admin',
        name: 'registreer_admin',
        pageBuilder: (context, state) => _noTransitionPage(const RegistreerAdminPage(), state),
      ),
      GoRoute(
        path: '/wagwoord_herstel',
        name: 'wagwoord_herstel',
        pageBuilder: (context, state) => _noTransitionPage(const WagwoordHerstelPage(), state),
      ),
      // Handle root URL with code parameter (for password reset emails)
      GoRoute(
        path: '/',
        name: 'root',
        redirect: (context, state) {
          final code = state.uri.queryParameters['code'];
          if (code != null) {
            // Redirect to password reset page with code parameter
            return '/wagwoord_herstel?code=$code';
          }
          return '/teken_in';
        },
      ),
      GoRoute(
        path: '/logout',
        name: 'logout',
        redirect: (context, state) => '/teken_in',
      ),
      GoRoute(
        path: '/wag_goedkeuring',
        name: 'wag_goedkeuring',
        pageBuilder: (context, state) => _noTransitionPage(const WagVirGoedkeuringPage(), state),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: DashboardPage()), state),
      ),
      GoRoute(
        path: '/spyskaart',
        name: 'spyskaart',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: SpyskaartBestuurPage()), state),
      ),
      GoRoute(
        path: '/week_spyskaart',
        name: 'week_spyskaart',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: WeekSpyskaartPage()), state),
      ),
      GoRoute(
        path: '/templates/kositem',
        name: 'templates_kositem',
        pageBuilder: (context, state) {
          final String? initialEditId = state.uri.queryParameters['edit'];
          return _noTransitionPage(
            AdminAccessGuard(child: KositemTemplaatPage(initialEditKosItemId: initialEditId)),
            state,
          );
        },
      ),
      GoRoute(
        path: '/templates/week',
        name: 'templates_week',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: WeekTemplaatPage()), state),
      ),
      GoRoute(
        path: '/bestellings',
        name: 'bestellings',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: BestellingBestuurPage()), state),
      ),
      GoRoute(
        path: '/gebruikers',
        name: 'gebruikers',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: GebruikersBestuurPage()), state),
      ),
      GoRoute(
        path: '/toelae',
        name: 'toelae',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: ToelaeMainPage()), state),
      ),
      GoRoute(
        path: '/toelae/bestuur',
        name: 'toelae_bestuur',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: ToelaeBestuurPage()), state),
      ),
      GoRoute(
        path: '/toelae/gebruiker_tipes',
        name: 'toelae_gebruiker_tipes',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: GebruikerTipesToelaePage()), state),
      ),
      GoRoute(
        path: '/toelae/transaksies',
        name: 'toelae_transaksies',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: TransaksieGeskiedenisPage()), state),
      ),
      GoRoute(
        path: '/kennisgewings',
        name: 'kennisgewings',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: KennisgewingsPage()), state),
      ),
      GoRoute(
        path: '/verslae',
        name: 'verslae',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: VerslaePage()), state),
      ),
      GoRoute(
        path: '/verslae/terugvoer',
        name: 'verslae_terugvoer',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: VerslaePage(showTerugvoerOnly: true)), state),
      ),
      GoRoute(
        path: '/instellings',
        name: 'instellings',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: InstellingsPage()), state),
      ),
      GoRoute(
        path: '/hulp',
        name: 'hulp',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: HulpPage()), state),
      ),
      GoRoute(
        path: '/profiel',
        name: 'profiel',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: ProfielPage()), state),
      ),
      GoRoute(
        path: '/db-test',
        name: 'db_test',
        pageBuilder: (context, state) => _noTransitionPage(const AdminAccessGuard(child: DbTestPage()), state),
      ),
    ],
  );
});

// Removed unused _builder helper

// Custom page builder with no transition animation
Page<dynamic> _noTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: PageScaffold(title: state.name ?? '', child: child),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child; // No animation, instant transition
    },
  );
}
