import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/wawu_merch/merch_auth/sign_up.dart';
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_main.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar

class SignInMerch extends StatefulWidget {
  const SignInMerch({super.key});

  @override
  State<SignInMerch> createState() => _SignInMerchState();
}

class _SignInMerchState extends State<SignInMerch> {
  bool isChecked = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Listen for errors from UserProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProvider.hasError &&
              userProvider.errorMessage != null &&
              !_hasShownError) {
            CustomSnackBar.show(
              context,
              message: userProvider.errorMessage!,
              isError: true,
            );
            _hasShownError = true; // Set flag to true after showing
            // It's crucial to clear the error state in the provider
            // after it has been displayed to the user.
            userProvider.resetState(); // Assuming resetState() or clearError()
          } else if (!userProvider.hasError && _hasShownError) {
            // Reset flag if error is cleared in provider
            _hasShownError = false;
          }
        });

        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 35.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIntroBar(
                    text: 'Welcome Back',
                    desc: "We're not gonna get tired of you, that's a promise.",
                  ),
                  CustomTextfield(
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    labelTextStyle2: true,
                    controller: emailController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    labelTextStyle2: true,
                    controller: passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Forgot Password',
                    style: TextStyle(color: wawuColors.buttonSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Show loading indicator when authentication is in progress
                  if (userProvider.isLoading)
                    CustomButton(
                      color: wawuColors.buttonPrimary,
                      // textColor: Colors.white,
                      function: () {}, // Empty function when loading
                      widget: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),

                  // Removed the old inline error Text widget for userProvider.
                  // if (userProvider.hasError)
                  //   Padding(
                  //     padding: const EdgeInsets.only(bottom: 10.0),
                  //     child: Text(
                  //       userProvider.errorMessage ?? 'An error occurred',
                  //       style: TextStyle(color: Colors.red),
                  //       textAlign: TextAlign.center,
                  //     ),
                  //   ),
                  if (!userProvider
                      .isLoading) // Show button only when not loading
                    CustomButton(
                      function: () async {
                        // Basic validation for empty fields
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          CustomSnackBar.show(
                            context,
                            message: 'Please enter your email and password.',
                            isError: true,
                          );
                          return;
                        }

                        // Call login method from provider
                        await userProvider.login(
                          emailController.text,
                          passwordController.text,
                        );

                        // Only navigate if the widget is still mounted and login was successful
                        if (mounted &&
                            userProvider.isSuccess &&
                            userProvider.currentUser != null) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WawuMerchMain(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      widget: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      color: wawuColors.buttonPrimary,
                      textColor: Colors.white,
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap:
                            userProvider.isLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignUpMerch(),
                                    ),
                                  );
                                },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: wawuColors.buttonSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
