import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';

class HomeCards extends StatelessWidget {
  const HomeCards({super.key, required this.summary});

  final PointSummary summary;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final numberFormatter = localization;
    final cards = <Widget>[
      _SummaryCard(
        title: localization.translate('balanceCardTitle'),
        value: numberFormatter.formatNumber(summary.balance),
        subtitle: localization.translate('balanceLabel'),
        icon: Icons.wallet,
      ),
      _SummaryCard(
        title: localization.translate('ytdTotalsTitle'),
        value: numberFormatter.formatNumber(summary.ytdEarnings),
        subtitle: '+${numberFormatter.formatNumber(summary.ytdEarnings - summary.ytdRedemptions)}',
        icon: Icons.trending_up,
      ),
      UpcomingExpirationCard(expirations: summary.upcomingExpirations),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final columnCount = isWide ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: columnCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 3.2 : 1.6,
          children: cards,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$title, $value $subtitle',
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingExpirationCard extends StatelessWidget {
  const UpcomingExpirationCard({super.key, required this.expirations});

  final List<ExpirationNotice> expirations;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('upcomingExpirationsTitle'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (expirations.isEmpty)
              Text(localization.translate('upcomingExpirationsEmpty'))
            else
              ...expirations.map((expiration) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MergeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.timelapse,
                            color: theme.colorScheme.tertiary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expiration.lotId,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatMediumDate(expiration.expiresOn),
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                AppLocalizations.of(context)
                                    .formatNumber(expiration.points),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
