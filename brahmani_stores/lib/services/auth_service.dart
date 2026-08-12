import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys
  static const String _usersKey = 'mock_users_db';
  static const String _sessionKey = 'isLoggedIn';
  static const String _currentUserKey = 'currentUsername';

  /// Hashes the password with SHA-256 for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Retrieves the mock "database" of users
  Future<Map<String, dynamic>> _getUsersDb() async {
    final usersStr = await _storage.read(key: _usersKey);
    if (usersStr != null) {
      return jsonDecode(usersStr);
    }
    return {};
  }

  /// Registers a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String mobile,
    required String password,
  }) async {
    try {
      final usersDb = await _getUsersDb();

      // Check if user already exists
      if (usersDb.containsKey(username)) {
        return {'success': false, 'message': 'આ યુઝરનેમ પહેલેથી જ અસ્તિત્વમાં છે.'}; // Username already exists
      }

      // Hash password and store
      final hashedPassword = _hashPassword(password);
      usersDb[username] = {
        'mobile': mobile,
        'password': hashedPassword,
      };

      await _storage.write(key: _usersKey, value: jsonEncode(usersDb));
      return {'success': true, 'message': 'નોંધણી સફળ રહી.'}; // Registration successful
    } catch (e) {
      return {'success': false, 'message': 'ભૂલ આવી છે. કૃપા કરીને ફરી પ્રયાસ કરો.'}; // Error occurred
    }
  }

  /// Authenticates a user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final usersDb = await _getUsersDb();

      if (!usersDb.containsKey(username)) {
        return {'success': false, 'message': 'યુઝરનેમ અથવા પાસવર્ડ ખોટો છે.'}; // Invalid username or password
      }

      final userData = usersDb[username];
      final hashedPassword = _hashPassword(password);

      if (userData['password'] == hashedPassword) {
        // Create session
        await _storage.write(key: _sessionKey, value: 'true');
        await _storage.write(key: _currentUserKey, value: username);
        return {'success': true, 'message': 'લૉગિન સફળ.'}; // Login successful
      } else {
        return {'success': false, 'message': 'યુઝરનેમ અથવા પાસવર્ડ ખોટો છે.'}; // Invalid username or password
      }
    } catch (e) {
      return {'success': false, 'message': 'ભૂલ આવી છે. કૃપા કરીને ફરી પ્રયાસ કરો.'}; // Error occurred
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _currentUserKey);
  }

  /// Checks if a user is currently logged in
  Future<bool> isLoggedIn() async {
    final session = await _storage.read(key: _sessionKey);
    return session == 'true';
  }

  /// Gets the currently logged in username
  Future<String?> getCurrentUsername() async {
    return await _storage.read(key: _currentUserKey);
  }
}
