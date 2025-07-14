import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/new_password_screen/new_password_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final AuthService authService;
  final String email;

  /// Optional: countdown duration in seconds before resend becomes available
  final int resendCountdownSeconds;

  const OtpScreen({
    super.key,
    required this.authService,
    required this.email,
    this.resendCountdownSeconds = 60, // Default to 60 seconds
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;

  // Countdown timer variables
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdownSeconds = widget.resendCountdownSeconds;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length < 4) {
      return 'OTP must be at least 4 digits';
    }
    return null;
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.verifyOtp(
        widget.email,
        _otpController.text.trim(),
        type: 'password_reset',
      );

      _showSnackBar('OTP verified successfully!');

      // Navigate to new password screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => NewPasswordScreen(
                  authService: widget.authService,
                  email: widget.email,
                  otp: _otpController.text.trim(),
                ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await widget.authService.forgotPassword(widget.email);

      _showSnackBar('New OTP sent to your email!');
      _otpController.clear();

      // Restart countdown after successful resend
      _startCountdown();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  String _formatCountdown(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildResendButton() {
    if (_isResending) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!_canResend) {
      return Text(
        'Resend OTP in ${_formatCountdown(_countdownSeconds)}',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      );
    }

    return Text(
      'Resend OTP',
      style: TextStyle(
        color: wawuColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('Enter OTP', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 10),
              Text(
                'We sent a verification code to ${widget.email}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              CustomTextfield(
                controller: _otpController,
                hintText: '******',
                labelTextStyle2: true,
                keyboardType: TextInputType.number,
                validator: _validateOtp,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        (_canResend && !_isResending) ? _handleResendOtp : null,
                    child: _buildResendButton(),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              CustomButton(
                function: _isLoading ? null : _handleVerifyOtp,
                widget:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Verify OTP',
                          style: TextStyle(color: Colors.white),
                        ),
                color: _isLoading ? Colors.grey : wawuColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
