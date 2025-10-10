import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'controllers/media_ingestion_controller.dart';
import 'controllers/preference_controller.dart';
import 'l10n/app_localizations.dart';
import 'models/mock_data.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/import_screen.dart';
import 'ui/screens/ledger_screen.dart';
import 'ui/screens/manual_review_screen.dart';
import 'ui/screens/settings_screen.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> navigatorKey,
  DashboardData data,
  PreferenceController preferences,
  MediaIngestionController ingestionController,
) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/dashboard',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          final localization = AppLocalizations.of(context);
          return Scaffold(
            body: SafeArea(child: child),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _indexForLocation(state.uri.path),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                    break;
                  case 1:
                    context.go('/ledger');
                    break;
                  case 2:
                    context.go('/manual-review');
                    break;
                  case 3:
                    context.go('/import');
                    break;
                  case 4:
                    context.go('/settings');
                    break;
                }
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: localization.translate('dashboard'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: localization.translate('ledger'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.rule_folder_outlined),
                  selectedIcon: const Icon(Icons.rule_folder),
                  label: localization.translate('manualReview'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.file_upload_outlined),
                  selectedIcon: const Icon(Icons.file_upload),
                  label: localization.translate('import'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: localization.translate('settings'),
                ),
              ],
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => DashboardScreen(data: data),
          ),
          GoRoute(
            path: '/ledger',
            name: 'ledger',
            builder: (context, state) => LedgerScreen(ledger: data.ledger),
          ),
          GoRoute(
            path: '/manual-review',
            name: 'manualReview',
            builder: (context, state) =>
                ManualReviewScreen(reviewQueue: data.reviewQueue),
          ),
          GoRoute(
            path: '/import',
            name: 'import',
            builder: (context, state) =>
                ImportScreen(controller: ingestionController),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => SettingsScreen(
              preferences: preferences,
              ingestionController: ingestionController,
            ),
          ),
        ],
      ),
    ],
  );
}

int _indexForLocation(String location) {
  switch (location) {
    case '/dashboard':
      return 0;
    case '/ledger':
      return 1;
    case '/manual-review':
      return 2;
    case '/import':
      return 3;
    case '/settings':
      return 4;
    default:
      return 0;
  }
}
