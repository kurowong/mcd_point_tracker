import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';
import '../widgets/ledger_table.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key, required this.ledger});

  final List<LedgerEntry> ledger;

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
          LedgerTable(entries: ledger),
        ],
      ),
    );
  }
}
