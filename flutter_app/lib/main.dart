import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/semantics.dart';

import 'controllers/media_ingestion_controller.dart';
import 'controllers/preference_controller.dart';
import 'ingestion/media_repository.dart';
import 'l10n/app_localizations.dart';
import 'models/mock_data.dart';
import 'preference_scope.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mediaRepository = await MediaRepository.create();
  final mediaIngestionController =
      MediaIngestionController(repository: mediaRepository);
  await mediaIngestionController.initialize();
  runApp(McdPointTrackerApp(ingestionController: mediaIngestionController));
}

class McdPointTrackerApp extends StatefulWidget {
  const McdPointTrackerApp({
    super.key,
    required this.ingestionController,
  });

  final MediaIngestionController ingestionController;

  @override
  State<McdPointTrackerApp> createState() => _McdPointTrackerAppState();
}

class _McdPointTrackerAppState extends State<McdPointTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final PreferenceController _preferences;
  late final MediaIngestionController _mediaIngestionController;
  late final DashboardData _dashboardData;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _preferences = PreferenceController(initialThemeMode: ThemeMode.light);
    _mediaIngestionController = widget.ingestionController;
    _dashboardData = createDemoData();
    _router = createRouter(
      _navigatorKey,
      _dashboardData,
      _preferences,
      _mediaIngestionController,
    );
  }

  @override
  void dispose() {
    _preferences.dispose();
    _mediaIngestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = buildLightTheme(lightColorScheme());
    final darkTheme = buildDarkTheme(darkColorScheme());

    return AnimatedBuilder(
      animation: _preferences,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'MCD Point Tracker',
          routerConfig: _router,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _preferences.themeMode,
          locale: _preferences.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, routerChild) {
            return PreferenceScope(
              controller: _preferences,
              child: Semantics(
                sortKey: const OrdinalSortKey(0),
                explicitChildNodes: true,
                child: routerChild ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
