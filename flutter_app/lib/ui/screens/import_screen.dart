import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('import')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localization.translate('importDescription'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload CSV',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_present),
                    label: const Text('Choose file'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    value: true,
                    onChanged: (_) {},
                    title: const Text('Auto-ingest nightly files'),
                  ),
                  SwitchListTile.adaptive(
                    value: false,
                    onChanged: (_) {},
                    title: const Text('Send completion email'),
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
