import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/transaction_review_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/review_entry.dart';
import '../../models/transaction.dart';

class ManualReviewScreen extends StatefulWidget {
  const ManualReviewScreen({
    super.key,
    required this.controller,
  });

  final TransactionReviewController controller;

  @override
  State<ManualReviewScreen> createState() => _ManualReviewScreenState();
}

class _ManualReviewScreenState extends State<ManualReviewScreen> {
  final Map<String, TextEditingController> _pointsControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (final controller in _pointsControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<ReviewEntry> entries) {
    final existingKeys = _pointsControllers.keys.toSet();
    for (final entry in entries) {
      existingKeys.remove(entry.id);
      final controller = _pointsControllers.putIfAbsent(
        entry.id,
        () => TextEditingController(text: entry.editedPoints.toString()),
      );
      if (controller.text != entry.editedPoints.toString()) {
        controller
          ..text = entry.editedPoints.toString()
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
      }
      _focusNodes.putIfAbsent(entry.id, () => FocusNode());
    }
    for (final key in existingKeys) {
      _pointsControllers.remove(key)?.dispose();
      _focusNodes.remove(key)?.dispose();
    }
  }

  Future<void> _pickDate(BuildContext context, ReviewEntry entry) async {
    final localization = AppLocalizations.of(context);
    final selected = await showDatePicker(
      context: context,
      initialDate: entry.editedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: localization.translate('dateFieldLabel'),
    );
    if (selected != null) {
      await widget.controller.updateEntry(entry.id, date: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('manualReview')),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final entries = widget.controller.pendingEntries;
          _syncControllers(entries);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                localization.translate('manualReviewDescription'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                _EmptyState(localization: localization)
              else
                ...entries.map(
                  (entry) => _ReviewCard(
                    entry: entry,
                    controller: widget.controller,
                    localization: localization,
                    pointsController: _pointsControllers[entry.id]!,
                    focusNode: _focusNodes[entry.id]!,
                    onPickDate: () => _pickDate(context, entry),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.entry,
    required this.controller,
    required this.localization,
    required this.pointsController,
    required this.focusNode,
    required this.onPickDate,
  });

  final ReviewEntry entry;
  final TransactionReviewController controller;
  final AppLocalizations localization;
  final TextEditingController pointsController;
  final FocusNode focusNode;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        MaterialLocalizations.of(context).formatMediumDate(entry.editedDate);
    final confidenceLabel =
        '${localization.translate('minConfidenceLabel')}: '
        '${(entry.minConfidence * 100).toStringAsFixed(1)}%';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.flag, size: 18),
                  label: Text(localization.translate('needsReviewLabel')),
                  backgroundColor: theme.colorScheme.errorContainer,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  label: Text(confidenceLabel),
                  avatar: const Icon(Icons.insights_outlined, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('rawTextLabel'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            SelectableText(
              entry.rawText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _FieldContainer(
                  label: localization.translate('dateFieldLabel'),
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.event),
                    label: Text(formattedDate),
                  ),
                ),
                _FieldContainer(
                  label: localization.translate('typeFieldLabel'),
                  child: DropdownButton<TransactionType>(
                    value: entry.editedType,
                    items: TransactionType.values
                        .map(
                          (type) => DropdownMenuItem<TransactionType>(
                            value: type,
                            child: Text(_labelForType(type, localization)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        unawaited(
                          controller.updateEntry(entry.id, type: value),
                        );
                      }
                    },
                  ),
                ),
                _FieldContainer(
                  label: localization.translate('pointsFieldLabel'),
                  child: SizedBox(
                    width: 120,
                    child: TextField(
                      controller: pointsController,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      decoration: const InputDecoration(
                        prefixText: '+/- ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          unawaited(
                            controller.updateEntry(entry.id, points: parsed),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final success = await controller.approveEntry(entry.id);
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? localization.translate('approvedSnackbar')
                            : localization.translate('approveFailedSnackbar'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(localization.translate('approveAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(TransactionType type, AppLocalizations localization) {
    switch (type) {
      case TransactionType.earned:
        return localization.translate('transactionTypeEarned');
      case TransactionType.used:
        return localization.translate('transactionTypeUsed');
      case TransactionType.expired:
        return localization.translate('transactionTypeExpired');
    }
  }
}

class _FieldContainer extends StatelessWidget {
  const _FieldContainer({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.verified_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('noPendingRows'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
