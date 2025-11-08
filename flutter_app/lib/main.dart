import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/semantics.dart';

import 'controllers/ledger_controller.dart';
import 'controllers/media_ingestion_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/preference_controller.dart';
import 'controllers/transaction_review_controller.dart';
import 'data/app_database.dart';
import 'data/raw_media_repository.dart';
import 'data/settings_repository.dart';
import 'data/transaction_repository.dart';
import 'ingestion/text_recognition_service.dart';
import 'l10n/app_localizations.dart';
import 'models/mock_data.dart';
import 'preference_scope.dart';
import 'router.dart';
import 'services/expiration_notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final rawMediaRepository = RawMediaRepository(database.instance);
  final transactionRepository = TransactionRepository(database.instance);
  final settingsRepository = SettingsRepository(database.instance);
  final textRecognition = TextRecognitionService();
  final ledgerController = LedgerController(
    transactionRepository: transactionRepository,
  );
  await ledgerController.initialize();
  final notificationController = NotificationController(
    settingsRepository: settingsRepository,
    ledgerController: ledgerController,
    notificationService: ExpirationNotificationService(),
  );
  await notificationController.initialize();
  final reviewController = TransactionReviewController(
    repository: transactionRepository,
    ledgerController: ledgerController,
  );
  await reviewController.initialize();
  final mediaIngestionController = MediaIngestionController(
    mediaRepository: rawMediaRepository,
    settingsRepository: settingsRepository,
    textRecognition: textRecognition,
    reviewController: reviewController,
  );
  await mediaIngestionController.initialize();
  final themeMode = await settingsRepository.loadThemeMode();
  final locale = await settingsRepository.loadLocale();
  runApp(
    McdPointTrackerApp(
      database: database,
      ingestionController: mediaIngestionController,
      reviewController: reviewController,
      ledgerController: ledgerController,
      notificationController: notificationController,
      textRecognition: textRecognition,
      settingsRepository: settingsRepository,
      initialThemeMode: themeMode,
      initialLocale: locale,
    ),
  );
}

class McdPointTrackerApp extends StatefulWidget {
  const McdPointTrackerApp({
    super.key,
    required this.database,
    required this.ingestionController,
    required this.reviewController,
    required this.ledgerController,
    required this.notificationController,
    required this.textRecognition,
    required this.settingsRepository,
    required this.initialThemeMode,
    required this.initialLocale,
  });

  final AppDatabase database;
  final MediaIngestionController ingestionController;
  final TransactionReviewController reviewController;
  final LedgerController ledgerController;
  final NotificationController notificationController;
  final TextRecognitionService textRecognition;
  final SettingsRepository settingsRepository;
  final ThemeMode initialThemeMode;
  final Locale? initialLocale;

  @override
  State<McdPointTrackerApp> createState() => _McdPointTrackerAppState();
}

class _McdPointTrackerAppState extends State<McdPointTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final PreferenceController _preferences;
  late final MediaIngestionController _mediaIngestionController;
  late final TransactionReviewController _reviewController;
  late final LedgerController _ledgerController;
  late final NotificationController _notificationController;
  late final TextRecognitionService _textRecognition;
  late final DashboardData _dashboardData;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _preferences = PreferenceController(
      repository: widget.settingsRepository,
      initialThemeMode: widget.initialThemeMode,
      initialLocale: widget.initialLocale,
    );
    _mediaIngestionController = widget.ingestionController;
    _reviewController = widget.reviewController;
    _ledgerController = widget.ledgerController;
    _notificationController = widget.notificationController;
    _textRecognition = widget.textRecognition;
    _dashboardData = createDemoData();
    _router = createRouter(
      _navigatorKey,
      _dashboardData,
      _preferences,
      _mediaIngestionController,
      _reviewController,
      _ledgerController,
      _notificationController,
    );
  }

  @override
  void dispose() {
    _preferences.dispose();
    _mediaIngestionController.dispose();
    _reviewController.dispose();
    _ledgerController.dispose();
    _notificationController.dispose();
    unawaited(_textRecognition.dispose());
    unawaited(widget.database.close());
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
