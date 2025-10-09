import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';
import '../widgets/review_queue_list.dart';

class ManualReviewScreen extends StatelessWidget {
  const ManualReviewScreen({super.key, required this.reviewQueue});

  final List<ReviewItem> reviewQueue;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('manualReview')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localization.translate('manualReviewDescription'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _QuickActions(localization: localization),
          const SizedBox(height: 16),
          ReviewQueueList(items: reviewQueue),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _ActionConfig(
        icon: Icons.done_all,
        label: localization.translate('bulkApprove'),
      ),
      _ActionConfig(
        icon: Icons.upload_file,
        label: localization.translate('exportCsv'),
      ),
      _ActionConfig(
        icon: Icons.playlist_add,
        label: localization.translate('addAdjustment'),
      ),
    ];

    return Semantics(
      label: localization.translate('quickActions'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.translate('quickActions'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => ElevatedButton.icon(
                        icon: Icon(action.icon),
                        label: Text(action.label),
                        onPressed: () {},
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionConfig {
  const _ActionConfig({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
