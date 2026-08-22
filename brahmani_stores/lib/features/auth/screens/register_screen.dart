import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? googleData;
  
  const RegisterScreen({super.key, this.googleData});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _avatarFile;
  String? _googleAvatarUrl;
  bool _showOtpScreen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.googleData != null) {
      _emailController.text = widget.googleData!['email'] ?? '';
      _firstNameController.text = widget.googleData!['firstName'] ?? '';
      _lastNameController.text = widget.googleData!['lastName'] ?? '';
      _googleAvatarUrl = widget.googleData!['avatarUrl'];
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
        _googleAvatarUrl = null; // Clear google avatar if user picks a custom one
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'કૃપા કરીને પાસવર્ડ દાખલ કરો'; // Please enter password
    }
    if (value.length < 8) {
      return 'પાસવર્ડ ઓછામાં ઓછા 8 અક્ષરોનો હોવો જોઈએ'; // Min 8 chars
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'પાસવર્ડમાં એક કેપિટલ અક્ષર હોવો જરૂરી છે'; // Uppercase req
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'પાસવર્ડમાં એક નાનો અક્ષર હોવો જરૂરી છે'; // Lowercase req
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'પાસવર્ડમાં એક નંબર હોવો જરૂરી છે'; // Number req
    }
    if (!value.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'પાસવર્ડમાં એક ખાસ ચિન્હ હોવું જરૂરી છે'; // Special char req
    }
    return null;
  }

  void _onRegister() async {
    if (_avatarFile == null && (_googleAvatarUrl == null || _googleAvatarUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('કૃપા કરીને પ્રોફાઇલ ફોટો પસંદ કરો'), // Please select profile photo
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).sendOtp(
        _emailController.text,
        _firstNameController.text,
        _lastNameController.text,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('તમારા ઈમેલ પર OTP મોકલવામાં આવ્યો છે.'), // OTP sent
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        setState(() {
          _showOtpScreen = true;
        });
      }
    }
  }

  Future<void> _onOtpVerify(String otpCode) async {
    final formData = FormData.fromMap({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'otpCode': otpCode,
    });

    if (_avatarFile != null) {
      formData.files.add(MapEntry(
          'avatar', await MultipartFile.fromFile(_avatarFile!.path, filename: 'avatar.jpg')));
    } else if (_googleAvatarUrl != null) {
      formData.fields.add(MapEntry('avatarUrl', _googleAvatarUrl!));
    }

    final success = await ref.read(authProvider.notifier).register(formData);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('વેરિફિકેશન સફળ! ખાતું બની ગયું છે.'), // Verification successful! Account created.
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.go('/login');
    }
  }

  Future<void> _onOtpResend() async {
    final success = await ref.read(authProvider.notifier).sendOtp(
      _emailController.text,
      _firstNameController.text,
      _lastNameController.text,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('નવો OTP મોકલવામાં આવ્યો છે.'), // New OTP sent
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showOtpScreen ? 'OTP વેરિફિકેશન' : 'નવું ખાતું બનાવો'), // Create new account or OTP
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
            if (_showOtpScreen) {
              setState(() { _showOtpScreen = false; });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: _showOtpScreen ? OtpVerificationWidget(
          email: _emailController.text,
          onVerify: _onOtpVerify,
          onResend: _onOtpResend,
        ) : SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.surfaceDark,
                          backgroundImage: _avatarFile != null 
                              ? FileImage(_avatarFile!) 
                              : (_googleAvatarUrl != null && _googleAvatarUrl!.isNotEmpty 
                                  ? NetworkImage(_googleAvatarUrl!) as ImageProvider 
                                  : null),
                          child: _avatarFile == null && (_googleAvatarUrl == null || _googleAvatarUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: AppTheme.textSecondary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: AppTheme.primaryDark, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'પ્રોફાઇલ ફોટો પસંદ કરો *', // Select profile photo *
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'પહેલું નામ'), // First name
                        validator: (v) => v!.isEmpty ? 'નામ દાખલ કરો' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'અટક'), // Last name
                        validator: (v) => v!.isEmpty ? 'અટક દાખલ કરો' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'ઇમેઇલ'), // Email
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'યોગ્ય ઇમેઇલ દાખલ કરો' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'મોબાઇલ નંબર'), // Mobile number
                  validator: (v) => v!.length < 10 ? 'યોગ્ય નંબર દાખલ કરો' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'પાસવર્ડ'), // Password
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'પાસવર્ડ ફરીથી દાખલ કરો'), // Confirm password
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'પાસવર્ડ મેળ ખાતા નથી'; // Passwords do not match
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _onRegister,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryDark,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('નોંધણી કરો'), // Register button
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
