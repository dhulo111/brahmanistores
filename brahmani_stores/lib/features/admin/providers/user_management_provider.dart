import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/admin_user_model.dart';

class UserManagementState {
  final bool isLoading;
  final String? error;
  final List<AdminUser> users;

  UserManagementState({
    this.isLoading = false,
    this.error,
    this.users = const [],
  });

  UserManagementState copyWith({
    bool? isLoading,
    String? error,
    List<AdminUser>? users,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      users: users ?? this.users,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final Dio _dio;

  UserManagementNotifier(this._dio) : super(UserManagementState()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/admin/users');
      final List<dynamic> data = response.data['users'];
      final usersList = data.map((json) => AdminUser.fromJson(json)).toList();
      state = state.copyWith(isLoading: false, users: usersList);
    } catch (e) {
      print('Error fetching users: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to fetch users');
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/admin/users/$id', data: data);
      if (response.statusCode == 200) {
        final updatedUser = AdminUser.fromJson(response.data['user']);
        final updatedList = state.users.map((u) {
          return u.id == id ? updatedUser : u;
        }).toList();
        state = state.copyWith(users: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _dio.delete('/admin/users/$id');
      if (response.statusCode == 200) {
        final updatedList = state.users.where((u) => u.id != id).toList();
        state = state.copyWith(users: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(ref.watch(apiClientProvider));
});
