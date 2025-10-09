import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';
import '../widgets/duplicate_warning_list.dart';
import '../widgets/home_cards.dart';
import '../widgets/ledger_table.dart';
import '../widgets/monthly_activity_chart.dart';
import '../widgets/review_queue_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('dashboard')),
      ),
      body: Semantics(
        container: true,
        label: localization.translate('dashboardDescription'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final body = ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                HomeCards(summary: data.summary),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MonthlyActivityChart(
                    monthlyActivity: data.monthlyActivity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: _sectionWidth(constraints.maxWidth),
                        child: LedgerTable(entries: data.ledger),
                      ),
                      SizedBox(
                        width: _sectionWidth(constraints.maxWidth),
                        child: DuplicateWarningList(warnings: data.duplicates),
                      ),
                      SizedBox(
                        width: _sectionWidth(constraints.maxWidth),
                        child: ReviewQueueList(items: data.reviewQueue),
                      ),
                    ],
                  ),
                ),
              ],
            );
            return body;
          },
        ),
      ),
    );
  }

  double _sectionWidth(double maxWidth) {
    if (maxWidth > 1280) {
      return maxWidth / 3 - 32;
    }
    if (maxWidth > 900) {
      return maxWidth / 2 - 32;
    }
    return maxWidth - 32;
  }
}
