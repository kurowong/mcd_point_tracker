import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/media_ingestion_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/preference_controller.dart';
import '../../controllers/transaction_review_controller.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.ingestionController,
    required this.reviewController,
    required this.notificationController,
  });

  final PreferenceController preferences;
  final MediaIngestionController ingestionController;
  final TransactionReviewController reviewController;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localization.translate('settingsDescription'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('themeSection'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(localization.translate('themeSystem')),
                        icon: const Icon(Icons.phone_android),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(localization.translate('themeLight')),
                        icon: const Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(localization.translate('themeDark')),
                        icon: const Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: <ThemeMode>{preferences.themeMode},
                    onSelectionChanged: (value) {
                      preferences.setThemeMode(value.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localization.translate('languageSection'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Locale?>(
                    value: preferences.locale,
                    items: [
                      DropdownMenuItem<Locale?>(
                        value: null,
                        child:
                            Text(localization.translate('languageSystem')),
                      ),
                      ...AppLocalizations.supportedLocales.map((locale) {
                        final label = locale.languageCode == 'es'
                            ? localization.translate('languageSpanish')
                            : localization.translate('languageEnglish');
                        return DropdownMenuItem<Locale?>(
                          value: locale,
                          child: Text(label),
                        );
                      }),
                    ],
                    onChanged: (value) => preferences.setLocale(value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: notificationController,
            builder: (context, _) {
              final enabled = notificationController.notificationsEnabled;
              final threshold = notificationController.threshold;
              final summary = notificationController.summary;
              final nextMonthLabel =
                  MaterialLocalizations.of(context)
                      .formatMonthYear(summary.nextMonthStart);
              final formattedTotal = AppLocalizations.of(context)
                  .formatNumber(summary.nextMonthTotalPoints);
              final notificationTitle =
                  localization.translate('notificationsTitle');
              final notificationDescription =
                  localization.translate('notificationsDescription');
              final thresholdLabel =
                  localization.translate('notificationThresholdLabel');
              final nextMonthTemplate =
                  localization.translate('notificationNextMonthLabel');
              final nextMonthText = nextMonthTemplate.replaceFirst(
                '{month}',
                nextMonthLabel,
              );
              final pointsSuffix =
                  localization.translate('pointsAbbreviation');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notificationTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: enabled,
                            onChanged: (value) =>
                                notificationController
                                    .setNotificationsEnabled(value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationDescription,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: enabled ? 1 : 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thresholdLabel,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              key: ValueKey(threshold),
                              initialValue: threshold.toString(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                prefixText: '',
                                suffixText: 'pts',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              enabled: enabled,
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null) {
                                  notificationController.setThreshold(parsed);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$nextMonthText $formattedTotal $pointsSuffix',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: ingestionController,
            builder: (context, _) {
              final retentionDays = ingestionController.retentionDays;
              final assetCount = ingestionController.assets.length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raw Capture Retention',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stored assets: $assetCount',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: retentionDays.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$retentionDays days',
                        onChanged: (value) => ingestionController
                            .setRetentionDays(value.round()),
                      ),
                      Text(
                        'Keep raw screenshots and captures for '
                        '$retentionDays days before cleanup.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final removed =
                                await ingestionController.cleanupExpiredAssets();
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  removed == 0
                                      ? 'No assets removed'
                                      : 'Removed $removed expired assets',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('Run cleanup now'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('dataManagementTitle'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.translate('dataManagementDescription'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  localization
                                      .translate('resetConfirmationTitle'),
                                ),
                                content: Text(
                                  localization
                                      .translate('resetConfirmationBody'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      localization.translate('cancelAction'),
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      localization
                                          .translate('confirmResetAction'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;
                      if (!confirmed) {
                        return;
                      }
                      await preferences.reset();
                      await reviewController.reset();
                      await ingestionController.resetAll(
                        deleteMediaFiles: true,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            localization.translate('resetCompleteMessage'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restart_alt),
                    label:
                        Text(localization.translate('fullResetActionLabel')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
