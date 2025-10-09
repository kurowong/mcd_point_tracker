import 'package:flutter/material.dart';

import '../../controllers/preference_controller.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.preferences});

  final PreferenceController preferences;

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
        ],
      ),
    );
  }
}
