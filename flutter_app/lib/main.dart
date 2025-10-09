import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ledger.dart';
import 'data.dart';
import 'ingest.dart';
import 'ocr.dart';
import 'parse.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  Ledger ledger = Ledger(today: DateTime(2024, 1, 20));
  final dao = TransactionsDao(AppDatabase().database);
  final ingest = IngestService();
  final ocr = OcrService();

  bool _isLoading = false;
  String _loadingMessage = '';

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppState() {
    ledger.add(Transaction(DateTime(2023, 1, 10), TransactionType.earned, 100));
    ledger.add(Transaction(DateTime(2023, 2, 10), TransactionType.earned, 100));
    ledger.add(Transaction(DateTime(2023, 3, 1), TransactionType.used, 80));
  }

  void _setLoading(bool loading, [String message = '']) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  Future<void> importFromGallery() async {
    try {
      _setLoading(true, 'Selecting image...');
      final file = await ingest.pickScreenshotFromGallery();
      if (file == null) {
        _setLoading(false);
        return;
      }

      _setLoading(true, 'Processing image with OCR...');
      final ocrResults = await ocr.extractTextWithConfidence(file);

      _setLoading(true, 'Parsing transactions...');
      final parsed = parseOcrResults(ocrResults);

      _setLoading(true, 'Saving to database...');
      // Use batch upsert for efficient deduplication
      await dao.upsertBatch(parsed);

      _setLoading(true, 'Updating calculations...');
      await _reloadFromDb();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> importFromVideo() async {
    try {
      _setLoading(true, 'Selecting video...');
      final file = await ingest.pickVideoFromFiles();
      if (file == null) {
        _setLoading(false);
        return;
      }

      final allParsed = <TransactionRecord>[];

      // Extract frames
      final frames = await ingest.extractFramesFromVideo(
        file,
        onProgress: (message) {
          _setLoading(true, message);
        },
      );

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        final frame = frames[i];
        _setLoading(true, 'Processing frame ${i + 1}/${frames.length}...');

        try {
          final ocrResults = await ocr.extractTextWithConfidence(frame.file);
          final parsed = parseOcrResults(ocrResults);
          allParsed.addAll(parsed);
        } catch (e) {
          // Continue processing other frames even if one fails
          print('Failed to process frame ${i + 1}: $e');
        }
      }

      _setLoading(true, 'Saving ${allParsed.length} transactions...');
      await dao.upsertBatch(allParsed);

      _setLoading(true, 'Updating calculations...');
      await _reloadFromDb();

      // Cleanup temporary frame files
      _setLoading(true, 'Cleaning up...');
      await ingest.cleanupFrames(frames);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<List<TransactionRecord>> getNeedsReview() async {
    return await dao.getNeedsReview();
  }

  Future<void> updateTransaction(TransactionRecord record) async {
    await dao.updateRecord(record);
    await _reloadFromDb();
  }

  Future<void> confirmAllReviewed(List<TransactionRecord> records) async {
    for (final record in records) {
      final updated = record.copyWith(needsReview: false);
      await dao.updateRecord(updated);
    }
    await _reloadFromDb();
  }
  
  Future<void> resetAllData() async {
    await dao.deleteAll();
    ledger = Ledger(today: DateTime.now());
    notifyListeners();
  }
  
  Future<void> loadSampleData() async {
    // Sample McDonald's data for testing
    final sampleData = [
      TransactionRecord(date: DateTime(2024, 1, 15), type: TransactionType.earned, points: 500),
      TransactionRecord(date: DateTime(2024, 2, 20), type: TransactionType.earned, points: 750),
      TransactionRecord(date: DateTime(2024, 3, 10), type: TransactionType.used, points: 200),
      TransactionRecord(date: DateTime(2024, 3, 25), type: TransactionType.earned, points: 300),
      TransactionRecord(date: DateTime(2024, 4, 5), type: TransactionType.used, points: 150),
      TransactionRecord(date: DateTime(2024, 4, 20), type: TransactionType.earned, points: 400),
      TransactionRecord(date: DateTime(2024, 5, 15), type: TransactionType.expired, points: 100, needsReview: true),
      TransactionRecord(date: DateTime(2024, 6, 1), type: TransactionType.earned, points: 600),
      TransactionRecord(date: DateTime(2024, 7, 10), type: TransactionType.used, points: 300),
      TransactionRecord(date: DateTime(2024, 8, 15), type: TransactionType.earned, points: 800, needsReview: true),
    ];
    
    await dao.upsertBatch(sampleData);
    await _reloadFromDb();
  }

  Future<void> _reloadFromDb() async {
    final rows = await dao.getAll();
    ledger = Ledger(today: ledger.today);
    for (final r in rows) {
      ledger.add(r.toLedgerTxn());
    }
    notifyListeners();
  }
}

void main() {
  runApp(const McdPointTrackerApp());
}

class McdPointTrackerApp extends StatelessWidget {
  const McdPointTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'McD Point Tracker',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const _HomeScreen(),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expiring = state.ledger.expiringSoon();
    final ytd = state.ledger.getYtdTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('McD Point Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.ledger.balance()}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'points available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // YTD Totals Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Year-to-Date ${DateTime.now().year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _YtdItem('Earned', ytd.earned, Colors.green),
                        _YtdItem('Used', ytd.used, Colors.orange),
                        _YtdItem('Expired', ytd.expired, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiring Soon Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expiring Soon (Next 3 Months)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (expiring.isEmpty)
                      const Text('No points expiring soon!')
                    else
                      ...expiring.map(
                        (b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_monthName(b.monthStart)),
                              Text(
                                '${b.total} points',
                                style: TextStyle(
                                  color: b.total > 1000 ? Colors.red : null,
                                  fontWeight: b.total > 1000
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lots Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Points Lots (${state.ledger.lots.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const _LotsScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.ledger.lots.isEmpty)
                      const Text('No lots available')
                    else
                      ...state.ledger.lots
                          .take(3)
                          .map(
                            (lot) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_yyyyMmDd(lot.earnedDate)),
                                  Text('${lot.remaining}/${lot.original}'),
                                ],
                              ),
                            ),
                          ),
                    if (state.ledger.lots.length > 3)
                      Text('... and ${state.ledger.lots.length - 3} more'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _IngestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Import Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YtdItem extends StatelessWidget {
  const _YtdItem(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LotsScreen extends StatelessWidget {
  const _LotsScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Points Lots')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.ledger.lots.length,
        itemBuilder: (context, index) {
          final lot = state.ledger.lots[index];
          return Card(
            child: ListTile(
              title: Text('Earned ${_yyyyMmDd(lot.earnedDate)}'),
              subtitle: Text(
                'Expires ${_yyyyMmDd(lot.expiry())}\n'
                'Original: ${lot.original} • Used: ${lot.consumed} • '
                'Expired: ${lot.expired} • Remaining: ${lot.remaining}',
              ),
              trailing: Text(
                '${lot.remaining}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: lot.remaining > 0 ? Colors.green : Colors.grey,
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _IngestScreen extends StatelessWidget {
  const _IngestScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Import Data')),
      body: state.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    state.loadingMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await state.importFromGallery();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Image import completed successfully!',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Import failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick screenshot from gallery'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await state.importFromVideo();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Video import completed successfully!',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Video import failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('Pick video from files'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _ReviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Review flagged transactions'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Video import extracts frames automatically\nand processes them with OCR',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await state.loadSampleData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sample data loaded!')),
                            );
                          },
                          child: const Text('Load Sample Data'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset All Data'),
                                content: const Text('This will delete all transactions. Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await state.resetAllData();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All data reset!')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Reset Data'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen();

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  List<TransactionRecord> _needsReview = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNeedsReview();
  }

  Future<void> _loadNeedsReview() async {
    final state = context.read<AppState>();
    final records = await state.getNeedsReview();
    setState(() {
      _needsReview = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Transactions')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsReview.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Transactions')),
        body: const Center(child: Text('No transactions need review!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_needsReview.length})'),
        actions: [
          TextButton(
            onPressed: () async {
              final state = context.read<AppState>();
              await state.confirmAllReviewed(_needsReview);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text(
              'Confirm All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _needsReview.length,
        itemBuilder: (context, index) {
          return _ReviewItem(
            record: _needsReview[index],
            onUpdate: (updated) {
              setState(() {
                _needsReview[index] = updated;
              });
            },
            onConfirm: (record) async {
              final state = context.read<AppState>();
              await state.updateTransaction(
                record.copyWith(needsReview: false),
              );
              setState(() {
                _needsReview.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  const _ReviewItem({
    required this.record,
    required this.onUpdate,
    required this.onConfirm,
  });

  final TransactionRecord record;
  final Function(TransactionRecord) onUpdate;
  final Function(TransactionRecord) onConfirm;

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  late DateTime _date;
  late TransactionType _type;
  late int _points;
  late TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _date = widget.record.date;
    _type = widget.record.type;
    _points = widget.record.points;
    _pointsController = TextEditingController(text: _points.toString());
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Date: ${_yyyyMmDd(_date)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                      _updateRecord();
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Type: '),
                DropdownButton<TransactionType>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                      value: TransactionType.earned,
                      child: Text('Earned'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.used,
                      child: Text('Used'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.expired,
                      child: Text('Expired'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                      });
                      _updateRecord();
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('Points: '),
                Expanded(
                  child: TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final points = int.tryParse(value);
                      if (points != null) {
                        _points = points;
                        _updateRecord();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onConfirm(_getCurrentRecord());
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateRecord() {
    widget.onUpdate(_getCurrentRecord());
  }

  TransactionRecord _getCurrentRecord() {
    return widget.record.copyWith(date: _date, type: _type, points: _points);
  }
}

String _yyyyMm(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
String _yyyyMmDd(DateTime d) =>
    '${_yyyyMm(d)}-${d.day.toString().padLeft(2, '0')}';

String _monthName(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
