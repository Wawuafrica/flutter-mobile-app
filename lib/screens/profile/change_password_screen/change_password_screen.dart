import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordScreen({super.key, required this.authService});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
    final email =
        Provider.of<UserProvider>(context, listen: false).currentUser?.email;

    // Check if email is null or empty
    if (email == null || email.isEmpty) {
      _showSnackBar(
        'User email not found. Please log in again.',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.resetPassword(
        email, // Now guaranteed to be non-null
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
              CustomTextfield(
                controller: _passwordController,
                labelText: 'Enter New Password',
                hintText: 'New Password',
                labelTextStyle2: true,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                keyboardType: TextInputType.text,
                suffixIcon:
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              SizedBox(height: 20),
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
