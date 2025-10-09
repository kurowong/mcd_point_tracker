import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';

class ReviewQueueList extends StatelessWidget {
  const ReviewQueueList({
    super.key,
    required this.items,
  });

  final List<ReviewItem> items;

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
              localization.translate('reviewQueueTitle'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(localization.translate('reviewQueueEmpty'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final submitted = MaterialLocalizations.of(context)
                      .formatMediumDate(item.submittedOn);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: theme.colorScheme.surfaceVariant,
                    child: ListTile(
                      title: Text(item.memberId),
                      subtitle: Text('${item.reason}\n$submitted'),
                      trailing: Text(
                        AppLocalizations.of(context)
                            .formatNumber(item.points),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
