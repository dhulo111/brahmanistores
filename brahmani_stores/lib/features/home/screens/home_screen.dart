import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ledger/providers/ledger_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user?.role == 'ADMIN') {
        ref.read(adminAllTransactionsProvider.notifier).fetchAllTransactions();
      } else {
        ref.read(myLedgerProvider.notifier).fetchMyLedger();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('બ્રહ્માણી પ્રોવિઝન સ્ટોર્સ'), // Brahmani Provision Stores
      ),
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: () async {
          if (isAdmin) {
            await ref.read(adminAllTransactionsProvider.notifier).fetchAllTransactions();
          } else {
            await ref.read(myLedgerProvider.notifier).fetchMyLedger();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isAdmin) ...[
                  _buildUserTotalDueCard(context, ref),
                  const SizedBox(height: 24),
                  _buildUserLatestEntriesCard(context, ref),
                ] else ...[
                  _buildAdminTotalDueCard(context, ref),
                  const SizedBox(height: 24),
                  _buildAdminLatestEntriesCard(context, ref),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTotalDueCard(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(adminAllTransactionsProvider);
    
    double totalUdhar = 0.0;
    double totalJama = 0.0;
    
    for (var tx in transactionsState.transactions) {
      if (tx.type == 'UDHAR') totalUdhar += tx.amount;
      if (tx.type == 'JAMA') totalJama += tx.amount;
    }
    
    final totalBaaki = totalUdhar - totalJama;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'કુલ માર્કેટ બાકી (Total Due)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_rounded,
                    size: 32,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              transactionsState.isLoading && transactionsState.transactions.isEmpty
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  : Text(
                      '₹${totalBaaki.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: totalBaaki < 0 ? Colors.green : Colors.redAccent,
                      ),
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('કુલ ઉધાર', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '₹${totalUdhar.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('કુલ જમા', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '₹${totalJama.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLatestEntriesCard(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(adminAllTransactionsProvider);
    final top4 = transactionsState.transactions.take(4).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'છેલ્લી 4 એન્ટ્રીઓ (Latest Entries)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              if (transactionsState.isLoading && transactionsState.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (top4.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('કોઈ એન્ટ્રી નથી', style: TextStyle(color: Colors.white54))),
                )
              else
                ...top4.map((tx) {
                  final isUdhar = tx.type == 'UDHAR';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      backgroundImage: tx.userAvatar != null && tx.userAvatar!.isNotEmpty
                          ? NetworkImage(tx.userAvatar!)
                          : null,
                      child: tx.userAvatar == null || tx.userAvatar!.isEmpty
                          ? Text(
                              tx.userName != null && tx.userName!.isNotEmpty
                                  ? tx.userName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      tx.userName ?? 'અજ્ઞાત', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    subtitle: Text(
                      tx.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isUdhar ? Colors.redAccent : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isUdhar ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTotalDueCard(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(myLedgerProvider);
    
    double totalUdhar = 0.0;
    double totalJama = 0.0;
    
    for (var tx in ledgerState.transactions) {
      if (tx.type == 'UDHAR') totalUdhar += tx.amount;
      if (tx.type == 'JAMA') totalJama += tx.amount;
    }
    
    final totalBaaki = totalUdhar - totalJama;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'મારું ખાતું (Total Due)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ledgerState.isLoading && ledgerState.transactions.isEmpty
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  : Text(
                      '₹${totalBaaki.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: totalBaaki < 0 ? Colors.green : Colors.redAccent,
                      ),
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('કુલ ઉધાર', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '₹${totalUdhar.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('કુલ જમા', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '₹${totalJama.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserLatestEntriesCard(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(myLedgerProvider);
    final top4 = ledgerState.transactions.take(4).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'છેલ્લી 4 એન્ટ્રીઓ (Latest Entries)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              if (ledgerState.isLoading && ledgerState.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (top4.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('કોઈ એન્ટ્રી નથી', style: TextStyle(color: Colors.white54))),
                )
              else
                ...top4.map((tx) {
                  final isUdhar = tx.type == 'UDHAR';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUdhar ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      child: Icon(
                        isUdhar ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUdhar ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tx.description, 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    trailing: Text(
                      '₹${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isUdhar ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

