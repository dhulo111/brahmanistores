import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/pending_user.dart';

class VerificationState {
  final bool isLoading;
  final String? error;
  final List<PendingUser> pendingUsers;

  VerificationState({
    this.isLoading = false,
    this.error,
    this.pendingUsers = const [],
  });

  VerificationState copyWith({
    bool? isLoading,
    String? error,
    List<PendingUser>? pendingUsers,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingUsers: pendingUsers ?? this.pendingUsers,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final Dio _dio;

  VerificationNotifier(this._dio) : super(VerificationState()) {
    fetchPendingUsers();
  }

  Future<void> fetchPendingUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/admin/users/pending');
      final usersList = (response.data['users'] as List)
          .map((user) => PendingUser.fromJson(user))
          .toList();
      state = state.copyWith(isLoading: false, pendingUsers: usersList);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['error'] ?? e.message ?? 'Unknown error',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> processUser(String userId, String action) async {
    // action: 'APPROVE' or 'REJECT'
    try {
      await _dio.post('/admin/users/approve', data: {
        'userId': userId,
        'action': action,
      });
      // Remove user from list
      final updatedList = state.pendingUsers.where((u) => u.id != userId).toList();
      state = state.copyWith(pendingUsers: updatedList);
      return true;
    } catch (e) {
      print('Failed to process user: $e');
      return false;
    }
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final dio = ref.watch(apiClientProvider);
  return VerificationNotifier(dio);
});
