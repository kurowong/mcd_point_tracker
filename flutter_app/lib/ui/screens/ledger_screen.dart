import 'package:flutter/material.dart';

import '../../controllers/ledger_controller.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/ledger_table.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('ledger')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localization.translate('ledgerDescription'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return LedgerTable(entries: controller.entries);
            },
          ),
        ],
      ),
    );
  }
}
