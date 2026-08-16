import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ledger/providers/ledger_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('બ્રહ્માણી પ્રોવિઝન સ્ટોર્સ'), // Brahmani Provision Stores
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isAdmin) ...[
                _buildQuickBalanceCard(context, ref),
                const SizedBox(height: 24),
              ],
              const Center(
                child: Text('અહીં ડેશબોર્ડ બતાવવામાં આવશે.'), // Dashboard will be shown here
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBalanceCard(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(myLedgerProvider);
    final isNegative = ledgerState.balance < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'મારું ખાતું (Total Due)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ledgerState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  : Text(
                      '₹${ledgerState.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isNegative ? Colors.green : Colors.redAccent,
                      ),
                    ),
            ],
          ),
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

