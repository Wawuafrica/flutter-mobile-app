import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/wawu_merch/merch_auth/sign_up.dart';
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_main.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class SignInMerch extends StatefulWidget {
  const SignInMerch({super.key});

  @override
  State<SignInMerch> createState() => _SignInMerchState();
}

class _SignInMerchState extends State<SignInMerch> {
  bool isChecked = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
                  SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    labelTextStyle2: true,
                    controller: passwordController,
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Forgot Password',
                    style: TextStyle(color: wawuColors.buttonSecondary),
                  ),
                  SizedBox(height: 20),

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

                  // Show error message if login failed
                  if (userProvider.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        userProvider.errorMessage ?? 'An error occurred',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (!userProvider
                      .isLoading) // Show button only when not loading
                    CustomButton(
                      function: () async {
                        // Call login method from provider
                        await userProvider.login(
                          emailController.text,
                          passwordController.text,
                        );

                        // Navigate on success
                        if (userProvider.isSuccess &&
                            userProvider.currentUser != null) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WawuMerchMain(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      widget: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      color: wawuColors.buttonPrimary,
                      textColor: Colors.white,
                    ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap:
                            userProvider.isLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignUpMerch(),
                                    ),
                                  );
                                },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: wawuColors.buttonSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
