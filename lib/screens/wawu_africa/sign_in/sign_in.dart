import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/main_screen/main_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
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
          body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 35.0),
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
                Center(child: CircularProgressIndicator()),
                
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
              
              CustomButton(
                function: () async {
                  // Call login method from provider
                  await userProvider.login(
                    emailController.text,
                    passwordController.text,
                  );
                  
                  // Navigate on success
                  if (userProvider.isSuccess && userProvider.currentUser != null) {
                    Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => MainScreen()),
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
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      color: wawuColors.buttonSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color.fromARGB(255, 209, 209, 209),
                    ),
                  ),
                  Text('Or', style: TextStyle(fontSize: 13)),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color.fromARGB(255, 209, 209, 209),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/google.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text('Continue with Google'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
              SizedBox(height: 10),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/apple.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text('Continue with Apple'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
              SizedBox(height: 10),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/facebook.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text('Continue with Facebook'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
