import 'package:flutter/material.dart';

import '../../controllers/media_ingestion_controller.dart';
import '../../controllers/preference_controller.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.ingestionController,
  });

  final PreferenceController preferences;
  final MediaIngestionController ingestionController;

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
        ],
      ),
    );
  }
}
