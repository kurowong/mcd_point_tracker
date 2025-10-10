import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';

class DuplicateWarningList extends StatelessWidget {
  const DuplicateWarningList({
    super.key,
    required this.warnings,
  });

  final List<DuplicateWarning> warnings;

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
              localization.translate('duplicateWarningsTitle'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (warnings.isEmpty)
              Text(localization.translate('duplicateWarningsEmpty'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final warning = warnings[index];
                  final flaggedLabel =
                      MaterialLocalizations.of(context)
                          .formatMediumDate(warning.flaggedOn);
                  return MergeSemantics(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.warning,
                          color: theme.colorScheme.secondary),
                      title: Text(warning.transactionId),
                      subtitle: Text(
                        '${localization.translate('flaggedOn')} $flaggedLabel',
                      ),
                      trailing: Chip(
                        label: Text('${warning.occurrences}x'),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: warnings.length,
              ),
          ],
        ),
      ),
    );
  }
}
