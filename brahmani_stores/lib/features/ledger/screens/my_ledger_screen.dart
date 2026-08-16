import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ledger_provider.dart';
import 'package:intl/intl.dart';

class MyLedgerScreen extends ConsumerWidget {
  const MyLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(myLedgerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('મારું ખાતું'), // My Ledger
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(myLedgerProvider.notifier).fetchMyLedger(),
          )
        ],
      ),
      body: ledgerState.isLoading && ledgerState.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(myLedgerProvider.notifier).fetchMyLedger(),
              child: Column(
                children: [
                  _buildBalanceCard(context, ledgerState.balance),
                  Expanded(
                    child: ledgerState.transactions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('કોઈ એન્ટ્રી નથી'))
                            ],
                          )
                        : ListView.builder(
                            itemCount: ledgerState.transactions.length,
                            itemBuilder: (context, index) {
                              final tx = ledgerState.transactions[index];
                              final isUdhar = tx.type == 'UDHAR';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isUdhar ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  child: Icon(
                                    isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isUdhar ? Colors.red : Colors.green,
                                  ),
                                ),
                                title: Text(tx.description),
                                subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt)),
                                trailing: Text(
                                  '₹${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isUdhar ? Colors.red : Colors.green,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    final isNegative = balance < 0; 
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'કુલ બાકી (Total Due)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: isNegative ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
