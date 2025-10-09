import 'package:flutter/material.dart';
import 'ledger.dart';

void main() {
  runApp(const McdPointTrackerApp());
}

class McdPointTrackerApp extends StatelessWidget {
  const McdPointTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = _buildSampleLedger();
    final expiring = sample.expiringSoon();
    return MaterialApp(
      title: 'McD Point Tracker',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('McD Point Tracker')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance: ${sample.balance()}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Expiring soon (next 3 months):', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...expiring.map((b) => Text('${_yyyyMm(b.monthStart)}: ${b.total}')),
              const SizedBox(height: 24),
              Text('Lots:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: sample.lots.length,
                  itemBuilder: (context, index) {
                    final lot = sample.lots[index];
                    return ListTile(
                      title: Text('Earned ${_yyyyMmDd(lot.earnedDate)} → Exp ${_yyyyMmDd(lot.expiry())}'),
                      subtitle: Text('orig ${lot.original} • used ${lot.consumed} • expired ${lot.expired} • remaining ${lot.remaining}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Ledger _buildSampleLedger() {
  final ledger = Ledger(today: DateTime(2024, 1, 20));
  ledger.add(Transaction(DateTime(2023, 1, 10), TransactionType.earned, 100));
  ledger.add(Transaction(DateTime(2023, 2, 10), TransactionType.earned, 100));
  ledger.add(Transaction(DateTime(2023, 3, 1), TransactionType.used, 80));
  return ledger;
}

String _yyyyMm(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
String _yyyyMmDd(DateTime d) => '${_yyyyMm(d)}-${d.day.toString().padLeft(2, '0')}';
