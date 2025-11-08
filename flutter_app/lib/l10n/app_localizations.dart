import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'MCD Point Tracker',
      'dashboard': 'Dashboard',
      'ledger': 'Ledger',
      'manualReview': 'Manual review',
      'import': 'Import',
      'settings': 'Settings',
      'balanceCardTitle': 'Current balance',
      'balanceLabel': 'Points',
      'ytdTotalsTitle': 'Year-to-date totals',
      'upcomingExpirationsTitle': 'Upcoming expirations',
      'upcomingExpirationsEmpty': 'No expirations in the next 60 days',
      'monthlyChartTitle': '12-month point activity',
      'ledgerTitle': 'Per-lot ledger',
      'duplicateWarningsTitle': 'Duplicate warnings',
      'duplicateWarningsEmpty': 'No duplicates detected',
      'reviewQueueTitle': 'Review queue',
      'reviewQueueEmpty': 'No items awaiting review',
      'importDescription': 'Upload point activity or configure imports.',
      'settingsDescription': 'Manage notification, language, and theme preferences.',
      'manualReviewDescription':
          'Inspect flagged activity, approve or reject transactions.',
      'ledgerDescription': 'Detailed activity grouped by lot.',
      'dashboardDescription':
          'Overview of balances, expirations, and pending actions.',
      'quickActions': 'Quick actions',
      'exportCsv': 'Export CSV',
      'addAdjustment': 'Add adjustment',
      'bulkApprove': 'Bulk approve',
      'themeLight': 'Light theme',
      'themeDark': 'Dark theme',
      'themeSection': 'Theme',
      'themeSystem': 'Match system',
      'languageEnglish': 'English',
      'languageSpanish': 'Spanish',
      'languageSystem': 'System default',
      'languageSection': 'Language',
      'legendEarned': 'Earned',
      'legendRedeemed': 'Redeemed',
      'flaggedOn': 'Flagged on',
      'columnLot': 'Lot ID',
      'columnAcquired': 'Acquired',
      'columnSource': 'Source',
      'columnPoints': 'Points',
      'columnStatus': 'Status',
      'needsReviewLabel': 'Needs review',
      'minConfidenceLabel': 'Min confidence',
      'rawTextLabel': 'Recognized text',
      'dateFieldLabel': 'Date',
      'typeFieldLabel': 'Type',
      'pointsFieldLabel': 'Points',
      'approveAction': 'Approve',
      'approvedSnackbar': 'Transaction approved',
      'approveFailedSnackbar':
          'Unable to approve – check for duplicates or missing values.',
      'transactionTypeEarned': 'Earned',
      'transactionTypeUsed': 'Used',
      'transactionTypeExpired': 'Expired',
      'noPendingRows': 'All caught up — no flagged transactions.',
      'dataManagementTitle': 'Data management',
      'dataManagementDescription':
          'Clear stored transactions, preferences, and raw media captures.',
      'resetConfirmationTitle': 'Reset all data?',
      'resetConfirmationBody':
          'This will delete pending reviews, ledger history, and cached media. '
              'This action cannot be undone.',
      'cancelAction': 'Cancel',
      'confirmResetAction': 'Reset',
      'fullResetActionLabel': 'Full reset',
      'resetCompleteMessage': 'All local data was cleared.',
      'notificationsTitle': 'Notifications',
      'notificationsDescription':
          'Send reminders 14 days before expiry at 9:00 MYT.',
      'notificationThresholdLabel': 'Next-month expiration threshold',
      'notificationNextMonthLabel':
          'Next month ({month}) expiring total:',
      'pointsAbbreviation': 'pts',
    },
    'es': {
      'appTitle': 'MCD Rastreador de Puntos',
      'dashboard': 'Tablero',
      'ledger': 'Libro mayor',
      'manualReview': 'Revisión manual',
      'import': 'Importación',
      'settings': 'Configuración',
      'balanceCardTitle': 'Saldo actual',
      'balanceLabel': 'Puntos',
      'ytdTotalsTitle': 'Totales del año',
      'upcomingExpirationsTitle': 'Vencimientos próximos',
      'upcomingExpirationsEmpty': 'Sin vencimientos en los próximos 60 días',
      'monthlyChartTitle': 'Actividad de 12 meses',
      'ledgerTitle': 'Libro por lotes',
      'duplicateWarningsTitle': 'Alertas de duplicados',
      'duplicateWarningsEmpty': 'No se detectaron duplicados',
      'reviewQueueTitle': 'Cola de revisión',
      'reviewQueueEmpty': 'No hay elementos en espera',
      'importDescription':
          'Sube actividad de puntos o configura importaciones automáticas.',
      'settingsDescription':
          'Administra notificaciones, idioma y preferencias de tema.',
      'manualReviewDescription':
          'Inspecciona la actividad marcada, aprueba o rechaza transacciones.',
      'ledgerDescription': 'Actividad detallada agrupada por lote.',
      'dashboardDescription':
          'Resumen de saldos, vencimientos y acciones pendientes.',
      'quickActions': 'Acciones rápidas',
      'exportCsv': 'Exportar CSV',
      'addAdjustment': 'Agregar ajuste',
      'bulkApprove': 'Aprobación masiva',
      'themeLight': 'Tema claro',
      'themeDark': 'Tema oscuro',
      'themeSection': 'Tema',
      'themeSystem': 'Coincidir con el sistema',
      'languageEnglish': 'Inglés',
      'languageSpanish': 'Español',
      'languageSystem': 'Predeterminado del sistema',
      'languageSection': 'Idioma',
      'legendEarned': 'Acumulados',
      'legendRedeemed': 'Canjeados',
      'flaggedOn': 'Marcado el',
      'columnLot': 'ID de lote',
      'columnAcquired': 'Adquirido',
      'columnSource': 'Fuente',
      'columnPoints': 'Puntos',
      'columnStatus': 'Estado',
      'needsReviewLabel': 'Requiere revisión',
      'minConfidenceLabel': 'Confianza mínima',
      'rawTextLabel': 'Texto reconocido',
      'dateFieldLabel': 'Fecha',
      'typeFieldLabel': 'Tipo',
      'pointsFieldLabel': 'Puntos',
      'approveAction': 'Aprobar',
      'approvedSnackbar': 'Transacción aprobada',
      'approveFailedSnackbar':
          'No se pudo aprobar; verifica duplicados o valores faltantes.',
      'transactionTypeEarned': 'Acumulados',
      'transactionTypeUsed': 'Canjeados',
      'transactionTypeExpired': 'Vencidos',
      'noPendingRows': 'Todo al día: no hay transacciones marcadas.',
      'dataManagementTitle': 'Administración de datos',
      'dataManagementDescription':
          'Borra transacciones, preferencias y capturas de medios guardadas.',
      'resetConfirmationTitle': '¿Restablecer todos los datos?',
      'resetConfirmationBody':
          'Esto eliminará las revisiones pendientes, el historial del libro y '
              'los medios almacenados. Esta acción no se puede deshacer.',
      'cancelAction': 'Cancelar',
      'confirmResetAction': 'Restablecer',
      'fullResetActionLabel': 'Restablecimiento total',
      'resetCompleteMessage': 'Todos los datos locales fueron eliminados.',
      'notificationsTitle': 'Notificaciones',
      'notificationsDescription':
          'Envía recordatorios 14 días antes del vencimiento a las 9:00 MYT.',
      'notificationThresholdLabel':
          'Umbral de vencimientos del próximo mes',
      'notificationNextMonthLabel':
          'Total a vencer el próximo mes ({month}):',
      'pointsAbbreviation': 'pts',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String formatCurrency(num value) {
    return NumberFormat.simpleCurrency(locale: locale.toLanguageTag())
        .format(value);
  }

  String formatNumber(num value) {
    return NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
