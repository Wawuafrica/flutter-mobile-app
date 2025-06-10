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

  const OtpScreen({super.key, required this.authService, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
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
    setState(() {
      _isResending = true;
    });

    try {
      await widget.authService.sendOtp(widget.email, type: 'password_reset');

      _showSnackBar('New OTP sent to your email!');
      _otpController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text('Enter OTP', style: TextStyle(fontSize: 22)),
              SizedBox(height: 10),
              Text(
                'We sent a verification code to ${widget.email}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: _otpController,
                hintText: '123456',
                labelTextStyle2: true,
                keyboardType: TextInputType.number,
                validator: _validateOtp,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isResending ? null : _handleResendOtp,
                    child:
                        _isResending
                            ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              'Resend OTP',
                              style: TextStyle(color: wawuColors.primary),
                            ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              CustomButton(
                function: _isLoading ? null : _handleVerifyOtp,
                widget:
                    _isLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
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
