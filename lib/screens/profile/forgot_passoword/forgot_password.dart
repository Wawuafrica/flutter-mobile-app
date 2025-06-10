import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/otp_screen/otp_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/services/auth_service.dart';

class ForgotPassword extends StatefulWidget {
  final AuthService authService;

  const ForgotPassword({super.key, required this.authService});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.forgotPassword(_emailController.text.trim());

      _showSnackBar('Password reset code sent to your email!');

      // Navigate to OTP screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OtpScreen(
                  authService: widget.authService,
                  email: _emailController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgotten Your Password?')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                "Hey Superwoman, it's normal to forget passwords. Just enter your email, and we'll send you a code to reset it.",
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: _emailController,
                hintText: 'Enter Your Email',
                labelTextStyle2: true,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              SizedBox(height: 10),
              CustomButton(
                function: _isLoading ? null : _handleForgotPassword,
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
                          'Continue',
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
