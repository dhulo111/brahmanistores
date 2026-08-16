import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/transaction_model.dart';

// --- My Ledger (Current User) ---

class LedgerState {
  final bool isLoading;
  final String? error;
  final double balance;
  final List<TransactionModel> transactions;

  LedgerState({
    this.isLoading = false,
    this.error,
    this.balance = 0.0,
    this.transactions = const [],
  });

  LedgerState copyWith({
    bool? isLoading,
    String? error,
    double? balance,
    List<TransactionModel>? transactions,
  }) {
    return LedgerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }
}

class MyLedgerNotifier extends StateNotifier<LedgerState> {
  final Dio api;
  MyLedgerNotifier(this.api) : super(LedgerState()) {
    fetchMyLedger();
  }

  Future<void> fetchMyLedger() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await api.get('/transactions');
      
      final txList = (response.data['transactions'] as List?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ?? [];
          
      // Calculate balance dynamically from transactions
      double calculatedBalance = 0.0;
      for (final tx in txList) {
        if (tx.type == 'UDHAR') {
          calculatedBalance += tx.amount;
        } else if (tx.type == 'JAMA') {
          calculatedBalance -= tx.amount;
        }
      }

      state = state.copyWith(
        isLoading: false,
        balance: calculatedBalance,
        transactions: txList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myLedgerProvider = StateNotifierProvider<MyLedgerNotifier, LedgerState>((ref) {
  return MyLedgerNotifier(ref.watch(apiClientProvider));
});


// --- Admin User Ledger (Specific User) ---

class AdminUserLedgerNotifier extends StateNotifier<LedgerState> {
  final String userId;
  final Dio api;

  AdminUserLedgerNotifier(this.userId, this.api) : super(LedgerState()) {
    fetchLedger();
  }

  Future<void> fetchLedger() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await api.get('/admin/users/$userId/transactions');
      
      final txList = (response.data['transactions'] as List?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ?? [];

      // Calculate balance dynamically from transactions
      double calculatedBalance = 0.0;
      for (final tx in txList) {
        if (tx.type == 'UDHAR') {
          calculatedBalance += tx.amount;
        } else if (tx.type == 'JAMA') {
          calculatedBalance -= tx.amount;
        }
      }

      state = state.copyWith(
        isLoading: false,
        balance: calculatedBalance,
        transactions: txList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addTransaction({
    required double amount,
    required String description,
    required String type, // 'UDHAR' or 'JAMA'
  }) async {
    try {
      await api.post('/admin/transactions', data: {
        'userId': userId,
        'amount': amount,
        'description': description,
        'type': type,
      });
      // Refresh after adding
      await fetchLedger();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final adminUserLedgerProvider = 
    StateNotifierProvider.family<AdminUserLedgerNotifier, LedgerState, String>((ref, userId) {
  return AdminUserLedgerNotifier(userId, ref.watch(apiClientProvider));
});


// --- Admin All Transactions (Global Ledger) ---

class AdminAllTransactionsNotifier extends StateNotifier<LedgerState> {
  final Dio api;

  AdminAllTransactionsNotifier(this.api) : super(LedgerState()) {
    fetchAllTransactions();
  }

  Future<void> fetchAllTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await api.get('/admin/transactions');
      
      final txList = (response.data['transactions'] as List?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ?? [];

      state = state.copyWith(
        isLoading: false,
        transactions: txList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addTransaction({
    required String userId,
    required double amount,
    required String description,
    required String type, // 'UDHAR' or 'JAMA'
  }) async {
    try {
      await api.post('/admin/transactions', data: {
        'userId': userId,
        'amount': amount,
        'description': description,
        'type': type,
      });
      // Refresh after adding
      await fetchAllTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final adminAllTransactionsProvider = 
    StateNotifierProvider<AdminAllTransactionsNotifier, LedgerState>((ref) {
  return AdminAllTransactionsNotifier(ref.watch(apiClientProvider));
});
