import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/admin_access_guard.dart';
import 'package:capstone_admin/features/auth/presentation/teken_in_page.dart';
import 'package:capstone_admin/features/auth/presentation/registreer_admin_page.dart';
import 'package:capstone_admin/features/auth/presentation/wag_vir_goedkeuring_page.dart';
import 'package:capstone_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:capstone_admin/features/spyskaart/presentation/spyskaart_bestuur_page.dart';
import 'package:capstone_admin/features/spyskaart/presentation/week_spyskaart_page.dart';
import 'package:capstone_admin/features/templates/presentation/kositem_templaat_page.dart';
import 'package:capstone_admin/features/templates/presentation/week_templaat_page.dart';
import 'package:capstone_admin/features/bestellings/presentation/bestelling_bestuur_page.dart';
import 'package:capstone_admin/features/gebruikers/presentation/gebruikers_bestuur_page.dart';
import 'package:capstone_admin/features/toelae/presentation/toelae_main_page.dart';
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
        builder: _builder(const TekenInPage()),
      ),
      GoRoute(
        path: '/registreer_admin',
        name: 'registreer_admin',
        builder: _builder(const RegistreerAdminPage()),
      ),
      GoRoute(
        path: '/logout',
        name: 'logout',
        redirect: (context, state) => '/teken_in',
      ),
      GoRoute(
        path: '/wag_goedkeuring',
        name: 'wag_goedkeuring',
        builder: _builder(const WagVirGoedkeuringPage()),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: _builder(const AdminAccessGuard(child: DashboardPage())),
      ),
      GoRoute(
        path: '/spyskaart',
        name: 'spyskaart',
        builder: _builder(const AdminAccessGuard(child: SpyskaartBestuurPage())),
      ),
      GoRoute(
        path: '/week_spyskaart',
        name: 'week_spyskaart',
        builder: _builder(const AdminAccessGuard(child: WeekSpyskaartPage())),
      ),
      GoRoute(
        path: '/templates/kositem',
        name: 'templates_kositem',
        builder: _builder(const AdminAccessGuard(child: KositemTemplaatPage())),
      ),
      GoRoute(
        path: '/templates/week',
        name: 'templates_week',
        builder: _builder(const AdminAccessGuard(child: WeekTemplaatPage())),
      ),
      GoRoute(
        path: '/bestellings',
        name: 'bestellings',
        builder: _builder(const AdminAccessGuard(child: BestellingBestuurPage())),
      ),
      GoRoute(
        path: '/gebruikers',
        name: 'gebruikers',
        builder: _builder(const AdminAccessGuard(child: GebruikersBestuurPage())),
      ),
            GoRoute(
              path: '/toelae',
              name: 'toelae',
              builder: _builder(const AdminAccessGuard(child: ToelaeMainPage())),
            ),
      GoRoute(
        path: '/kennisgewings',
        name: 'kennisgewings',
        builder: _builder(const AdminAccessGuard(child: KennisgewingsPage())),
      ),
      GoRoute(
        path: '/verslae',
        name: 'verslae',
        builder: _builder(const AdminAccessGuard(child: VerslaePage())),
      ),
      GoRoute(
        path: '/instellings',
        name: 'instellings',
        builder: _builder(const AdminAccessGuard(child: InstellingsPage())),
      ),
      GoRoute(
        path: '/hulp', 
        name: 'hulp', 
        builder: _builder(const AdminAccessGuard(child: HulpPage()))
      ),
      GoRoute(
        path: '/profiel',
        name: 'profiel',
        builder: _builder(const AdminAccessGuard(child: ProfielPage())),
      ),
      GoRoute(
        path: '/db-test',
        name: 'db_test',
        builder: _builder(const AdminAccessGuard(child: DbTestPage())),
      ),
    ],
  );
});

GoRouterWidgetBuilder _builder(Widget child) =>
    (BuildContext context, GoRouterState state) =>
        PageScaffold(title: state.name ?? '', child: child);
