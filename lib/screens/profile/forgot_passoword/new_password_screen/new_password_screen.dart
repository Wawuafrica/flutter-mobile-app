import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/services/auth_service.dart';

class NewPasswordScreen extends StatefulWidget {
  final AuthService authService;
  final String email;
  final String otp;

  const NewPasswordScreen({
    super.key,
    required this.authService,
    required this.email,
    required this.otp,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.resetPassword(
        widget.email,
        _passwordController.text,
        _confirmPasswordController.text,
      );

      _showSnackBar('Password reset successfully!');

      // Navigate back to login or home screen
      if (mounted) {
        // Pop all screens back to the login screen
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Or navigate to a specific screen
        // Navigator.pushNamedAndRemoveUntil(
        //   context,
        //   '/login',
        //   (route) => false,
        // );
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
      appBar: AppBar(title: Text('New Password')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Create a new password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Your new password must be different from your previous password.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              Stack(
                children: [
                  CustomTextfield(
                    controller: _passwordController,
                    labelText: 'Enter New Password',
                    hintText: 'New Password',
                    labelTextStyle2: true,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    keyboardType: TextInputType.text,
                    suffixIcon:
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                  ),
                  Positioned(
                    right: 12,
                    top:
                        _isLoading
                            ? 41
                            : 41, // Adjust based on your text field height
                    child: GestureDetector(
                      onTap:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _isLoading ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Stack(
                children: [
                  CustomTextfield(
                    controller: _confirmPasswordController,
                    labelText: 'Re-Enter New Password',
                    hintText: 'Confirm Password',
                    labelTextStyle2: true,
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    keyboardType: TextInputType.text,
                    suffixIcon:
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                  ),
                  Positioned(
                    right: 12,
                    top: 41, // Adjust based on your text field height
                    child: GestureDetector(
                      onTap:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _isLoading ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Password must contain:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 5),
              Text(
                '• At least 8 characters\n'
                '• One uppercase letter\n'
                '• One lowercase letter\n'
                '• One number',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 30),
              CustomButton(
                function: _isLoading ? null : _handleResetPassword,
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
                          'Confirm Changes',
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
