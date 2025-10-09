import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart';

class MonthlyActivityChart extends StatelessWidget {
  const MonthlyActivityChart({
    super.key,
    required this.monthlyActivity,
  });

  final List<MonthlyActivity> monthlyActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('monthlyChartTitle'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: _ChartCanvas(monthlyActivity: monthlyActivity),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegendDot(color: theme.colorScheme.primary),
                Text(localization.translate('legendEarned')),
                _LegendDot(color: theme.colorScheme.secondary),
                Text(localization.translate('legendRedeemed')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ChartCanvas extends StatelessWidget {
  const _ChartCanvas({required this.monthlyActivity});

  final List<MonthlyActivity> monthlyActivity;

  @override
  Widget build(BuildContext context) {
    final maxValue = monthlyActivity.fold<int>(0, (value, activity) {
      final localMax = math.max(activity.earned, activity.redeemed);
      return math.max(value, localMax);
    }).toDouble();

    final semanticLabel = _buildSemanticLabel(context, monthlyActivity);

    return Semantics(
      label: semanticLabel,
      child: CustomPaint(
        painter: _ChartPainter(
          activity: monthlyActivity,
          maxValue: maxValue == 0 ? 1 : maxValue,
          earnedColor: Theme.of(context).colorScheme.primary,
          redeemedColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  String _buildSemanticLabel(
      BuildContext context, List<MonthlyActivity> activity) {
    final localization = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer('12 month activity. ');
    for (final entry in activity) {
      buffer.write(
          '${localization.formatMediumDate(entry.month)}: earned ${l10n.formatNumber(entry.earned)}, redeemed ${l10n.formatNumber(entry.redeemed)}. ');
    }
    return buffer.toString();
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.activity,
    required this.maxValue,
    required this.earnedColor,
    required this.redeemedColor,
    required this.labelColor,
  });

  final List<MonthlyActivity> activity;
  final double maxValue;
  final Color earnedColor;
  final Color redeemedColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (activity.length * 2.5);
    final paintEarned = Paint()..color = earnedColor;
    final paintRedeemed = Paint()..color = redeemedColor.withOpacity(0.8);
    final baseLine = size.height - 24;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < activity.length; i++) {
      final entry = activity[i];
      final x = (i + 1) * barWidth * 2.5;
      final earnedHeight = baseLine * (entry.earned / maxValue);
      final redeemedHeight = baseLine * (entry.redeemed / maxValue);

      final earnedRect = Rect.fromLTWH(
        x - barWidth * 1.1,
        baseLine - earnedHeight,
        barWidth,
        earnedHeight,
      );
      final redeemedRect = Rect.fromLTWH(
        x - barWidth * 0.1,
        baseLine - redeemedHeight,
        barWidth,
        redeemedHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(earnedRect, const Radius.circular(4)),
        paintEarned,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(redeemedRect, const Radius.circular(4)),
        paintRedeemed,
      );

      final label = _formatMonth(entry.month);
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
        ),
      );
      textPainter.layout(maxWidth: barWidth * 1.8);
      textPainter.paint(
          canvas, Offset(x - (textPainter.width / 2), size.height - 20));
    }
  }

  String _formatMonth(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.year % 100}';
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.activity != activity ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.earnedColor != earnedColor ||
        oldDelegate.redeemedColor != redeemedColor;
  }
}
