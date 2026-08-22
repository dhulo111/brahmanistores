import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

class OtpVerificationWidget extends ConsumerStatefulWidget {
  final String email;
  final Future<void> Function(String otpCode) onVerify;
  final Future<void> Function() onResend;

  const OtpVerificationWidget({
    Key? key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  }) : super(key: key);

  @override
  ConsumerState<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends ConsumerState<OtpVerificationWidget> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને 4 આંકડાનો OTP દાખલ કરો')),
      );
      return;
    }
    await widget.onVerify(otpCode);
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    await widget.onResend();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              const Icon(Icons.mark_email_read_rounded, size: 80, color: AppTheme.primaryGreen),
              const SizedBox(height: 24),
              const Text(
                'ઈમેલ વેરિફિકેશન', // Email verification
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'અમે ${widget.email} પર 4 આંકડાનો OTP મોકલ્યો છે.\nકૃપા કરીને નીચે દાખલ કરો.', 
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    height: 70,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: AppTheme.surfaceDark.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.textSecondary, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: authState.isLoading ? null : _verifyOtp,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryDark,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('વેરીફાઈ કરો (Verify)'),
              ),
              
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: _canResend && !authState.isLoading ? _handleResend : null,
                child: Text(
                  _canResend 
                      ? 'ફરીથી OTP મોકલો (Resend OTP)' 
                      : 'Resend OTP in $_secondsRemaining s',
                  style: TextStyle(
                    color: _canResend ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
