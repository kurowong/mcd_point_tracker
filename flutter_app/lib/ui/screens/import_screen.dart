import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../controllers/media_ingestion_controller.dart';
import '../../ingestion/raw_media_metadata.dart';
import '../../l10n/app_localizations.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.controller});

  final MediaIngestionController controller;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _processingScreenshots = false;
  bool _processingVideos = false;
  StreamController<Uint8List>? _liveCaptureController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ImportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _liveCaptureController?.close();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleImportScreenshots() async {
    setState(() => _processingScreenshots = true);
    final report = await widget.controller.prepareScreenshotImport();
    if (!mounted) {
      return;
    }
    await _handleIngestionReport(report, includeDuplicates: false);
    if (!mounted) {
      return;
    }
    setState(() => _processingScreenshots = false);
  }

  Future<void> _handleImportVideos() async {
    setState(() => _processingVideos = true);
    final report = await widget.controller.prepareVideoImport();
    if (!mounted) {
      return;
    }
    await _handleIngestionReport(report, includeDuplicates: true);
    if (!mounted) {
      return;
    }
    setState(() => _processingVideos = false);
  }

  Future<void> _handleIngestionReport(
    IngestionReport report, {
    required bool includeDuplicates,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    if (report.total == 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No new media found.')),
      );
      return;
    }

    var allowDuplicates = includeDuplicates;
    if (report.hasDuplicates) {
      allowDuplicates = await _showDuplicateDialog(report.duplicates);
      if (!allowDuplicates) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Import cancelled.')),
        );
        return;
      }
    }

    await widget.controller
        .finalizeImport(report, includeDuplicates: allowDuplicates);
    messenger.showSnackBar(
      SnackBar(content: Text('Imported ${report.total} assets.')),
    );
  }

  Future<bool> _showDuplicateDialog(List<RawMediaMetadata> duplicates) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Potential duplicates detected'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Found ${duplicates.length} overlapping assets.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        itemCount: duplicates.length,
                        itemBuilder: (context, index) {
                          final item = duplicates[index];
                          return ListTile(
                            dense: true,
                            title: Text(item.prettyLabel),
                            subtitle: Text(
                              item.capturedAt.toLocal().toString(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Import anyway'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _toggleLiveCapture(bool value) async {
    if (value) {
      final granted = await widget.controller.ensureLiveCapturePermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accessibility permission is required to start.'),
          ),
        );
        return;
      }
      await _liveCaptureController?.close();
      final controller = StreamController<Uint8List>.broadcast();
      _liveCaptureController = controller;
      try {
        await widget.controller.startLiveCapture(controller.stream);
      } catch (error) {
        await controller.close();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start live capture: $error')),
        );
      }
    } else {
      await _liveCaptureController?.close();
      _liveCaptureController = null;
      widget.controller.stopLiveCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final assets = widget.controller.assets;
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('import')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localization.translate('importDescription'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device ingestion',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed:
                        _processingScreenshots ? null : _handleImportScreenshots,
                    icon: _processingScreenshots
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(_processingScreenshots
                        ? 'Importing screenshots...'
                        : 'Import screenshots'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _processingVideos ? null : _handleImportVideos,
                    icon: _processingVideos
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.video_library_outlined),
                    label: Text(_processingVideos
                        ? 'Importing videos...'
                        : 'Import gallery videos'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: widget.controller.liveCaptureActive,
                    onChanged: (value) => _toggleLiveCapture(value),
                    title: const Text('Enable live screen capture (beta)'),
                    subtitle: const Text(
                      'Requires accessibility permission on Android 14+',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stored raw media',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (assets.isEmpty)
                    const Text('No ingested assets yet.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = assets[index];
                        return ListTile(
                          leading: Icon(
                            item.type == RawMediaType.video
                                ? Icons.movie_creation_outlined
                                : item.type == RawMediaType.liveCapture
                                    ? Icons.cast_connected
                                    : Icons.image_outlined,
                          ),
                          title: Text(item.prettyLabel),
                          subtitle: Text(
                            '${item.type.name} • '
                            '${item.capturedAt.toLocal()} • '
                            'hash ${_shortHash(item.perceptualHash)}',
                          ),
                          trailing: item.frameSampleCount > 0
                              ? Text('${item.frameSampleCount} frames')
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortHash(String hash) {
  if (hash.isEmpty) {
    return 'n/a';
  }
  final end = min(6, hash.length);
  return hash.substring(0, end);
}
