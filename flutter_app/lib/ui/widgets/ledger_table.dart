import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';

class LedgerTable extends StatelessWidget {
  const LedgerTable({super.key, required this.entries});

  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('ledgerTitle'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Semantics(
                label: localization.translate('ledgerDescription'),
                child: DataTable(
                  columnSpacing: 24,
                  headingTextStyle: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  columns: [
                    DataColumn(
                      label: Text(localization.translate('columnLot')),
                    ),
                    DataColumn(
                      label: Text(localization.translate('columnAcquired')),
                    ),
                    DataColumn(
                      label: Text(localization.translate('columnSource')),
                    ),
                    DataColumn(
                      label: Text(localization.translate('columnPoints')),
                    ),
                    DataColumn(
                      label: Text(localization.translate('columnStatus')),
                    ),
                  ],
                  rows: entries
                      .map(
                        (entry) => DataRow(
                          cells: [
                            DataCell(Text(entry.lotId)),
                            DataCell(Text(MaterialLocalizations.of(context)
                                .formatShortDate(entry.acquiredOn))),
                            DataCell(Text(entry.source)),
                            DataCell(Text(AppLocalizations.of(context)
                                .formatNumber(entry.points))),
                            DataCell(Text(entry.status)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
