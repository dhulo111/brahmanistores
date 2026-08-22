import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api_client.dart';

import '../../profile/models/user_model.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final User? user;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  AuthNotifier(this._dio) : super(AuthState(
    isAuthenticated: Hive.box('auth').get('token') != null,
  )) {
    if (state.isAuthenticated) {
      _fetchProfile();
    }
  }

  Future<String?> _getFcmToken() async {
    try {
      await _messaging.requestPermission();
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['user'] != null) {
        state = state.copyWith(user: User.fromJson(response.data['user']));
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }
  }

  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fcmToken = await _getFcmToken();
      
      final response = await _dio.post('/auth/login', data: {
        'emailOrUsername': emailOrUsername,
        'password': password,
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

      final token = response.data['token'];
      if (token != null) {
        await Hive.box('auth').put('token', token);
        User? user;
        if (response.data['user'] != null) {
          user = User.fromJson(response.data['user']);
        }
        state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
        
        if (user == null) {
          _fetchProfile();
        }
        return true;
      }
      
      state = state.copyWith(isLoading: false, error: 'અજાણી ભૂલ'); // Unknown error
      return false;
    } on DioException catch (e) {
      String errorMessage = 'લૉગિન નિષ્ફળ ગયું'; // Login failed
      
      if (e.response != null && e.response!.data != null) {
         final serverError = e.response!.data['error'];
         if (serverError == 'error_invalid_credentials') {
           errorMessage = 'ઇમેઇલ અથવા પાસવર્ડ ખોટો છે'; // Invalid credentials
         } else if (serverError == 'error_pending_verification') {
           errorMessage = 'તમારું એકાઉન્ટ મંજૂરી માટે બાકી છે. મંજૂરી મળ્યા પછી તમે લોગીન કરી શકશો.'; // Pending verification
         } else if (serverError == 'error_account_rejected') {
           errorMessage = 'તમારું એકાઉન્ટ રદ કરવામાં આવ્યું છે.'; // Account rejected
         } else if (serverError == 'validation_error') {
           errorMessage = 'કૃપા કરીને બધી વિગતો યોગ્ય રીતે ભરો'; // Please fill correctly
         }
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Convert to Firebase Credential to get a Firebase ID Token!
      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth.UserCredential userCredential = await auth.FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to get Firebase Token');
        return null;
      }

      final fcmToken = await _getFcmToken();
      
      final response = await _dio.post('/auth/google-login', data: {
        'idToken': idToken,
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

      final token = response.data['token'];
      if (token != null) {
        await Hive.box('auth').put('token', token);
        User? user;
        if (response.data['user'] != null) {
          user = User.fromJson(response.data['user']);
        }
        state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
        
        if (user == null) {
          _fetchProfile();
        }
        return {'action': 'login', 'user': user};
      }
      
      state = state.copyWith(isLoading: false, error: 'અજાણી ભૂલ'); // Unknown error
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        // User not found, need to register
        state = state.copyWith(isLoading: false);
        return {'action': 'register', 'data': e.response!.data['googleData']};
      }
      
      String errorMessage = 'Google લૉગિન નિષ્ફળ ગયું';
      if (e.response != null && e.response!.data != null) {
         final serverError = e.response!.data['error'];
         if (serverError == 'error_pending_verification') {
           errorMessage = 'તમારું એકાઉન્ટ મંજૂરી માટે બાકી છે. મંજૂરી મળ્યા પછી તમે લોગીન કરી શકશો.';
         } else if (serverError == 'error_account_rejected') {
           errorMessage = 'તમારું એકાઉન્ટ રદ કરવામાં આવ્યું છે.';
         }
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Login Error: $e');
      return null;
    }
  }

  Future<bool> register(FormData formData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fcmToken = await _getFcmToken();
      if (fcmToken != null) {
        formData.fields.add(MapEntry('fcmToken', fcmToken));
      }
      
      await _dio.post('/auth/register', data: formData);
      // Automatically login or direct to login page
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'નોંધણી નિષ્ફળ ગઈ'; // Registration failed
      print('Register DioException: ${e.message}');
      
      if (e.response != null && e.response!.data != null) {
         print('Server Error Data: ${e.response!.data}');
         final serverError = e.response!.data['error'];
         if (serverError == 'error_email_in_use') {
           errorMessage = 'આ ઇમેઇલ પહેલેથી જ નોંધાયેલ છે'; // Email already registered
         } else if (serverError == 'error_avatar_required') {
           errorMessage = 'પ્રોફાઇલ ફોટો ફરજિયાત છે'; // Profile photo mandatory
         } else if (serverError == 'validation_error') {
           errorMessage = 'કૃપા કરીને બધી વિગતો યોગ્ય રીતે ભરો';
         } else if (serverError == 'error_avatar_upload_failed') {
           errorMessage = 'પ્રોફાઇલ ફોટો અપલોડ કરવામાં નિષ્ફળ. (Supabase Error)'; // Avatar upload failed
         } else if (serverError == 'error_internal_server') {
           errorMessage = 'સર્વર માં ખામી છે. (Database or Server Error)'; // Server error
         } else if (serverError == 'error_invalid_otp') {
           errorMessage = 'તમે દાખલ કરેલો OTP ખોટો છે';
         } else if (serverError == 'error_otp_expired') {
           errorMessage = 'આ OTP એક્સપાયર થઈ ગયો છે';
         } else if (serverError == 'error_otp_not_found') {
           errorMessage = 'કૃપા કરીને ફરીથી OTP મોકલો';
         }
      } else {
        print('Error Response was null. Error: $e');
        errorMessage = 'કનેક્શન નિષ્ફળ (Connection Failed): ${e.message}';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> sendOtp(String email, String firstName, String lastName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/auth/send-otp', data: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'OTP મોકલવામાં નિષ્ફળતા'; // Failed to send OTP
      if (e.response != null && e.response!.data != null) {
         final serverError = e.response!.data['error'];
         if (serverError == 'error_email_in_use') {
           errorMessage = 'આ ઇમેઇલ પહેલેથી જ નોંધાયેલ છે'; // Email already registered
         } else {
           errorMessage = e.response!.data['message'] ?? errorMessage;
         }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'OTP Error: $e');
      return false;
    }
  }

  Future<bool> updateProfile(String firstName, String lastName, String? phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.put('/auth/profile', data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      });

      if (response.data['user'] != null) {
        state = state.copyWith(
          isLoading: false,
          user: User.fromJson(response.data['user']),
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to parse user data');
      return false;
    } on DioException catch (e) {
      String errorMessage = 'અપડેટ નિષ્ફળ (Update Failed)';
      if (e.response != null && e.response!.data != null) {
         final serverError = e.response!.data['error'];
         if (serverError == 'validation_error') {
           errorMessage = 'કૃપા કરીને બધી વિગતો યોગ્ય રીતે ભરો';
         } else {
           errorMessage = e.response!.data['message'] ?? errorMessage;
         }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null, isAuthenticated: state.isAuthenticated, isLoading: state.isLoading);
  }

  void logout() async {
    await Hive.box('auth').delete('token');
    state = state.copyWith(isAuthenticated: false, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthNotifier(dio);
});
