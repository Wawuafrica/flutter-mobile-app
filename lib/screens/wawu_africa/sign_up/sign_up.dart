import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/account_type/account_type.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isChecked = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    countryController.dispose();
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
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 35.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIntroBar(
                    text: 'Sign Up',
                    desc: 'Wanna show off your superpower?  Start here.',
                  ),
                  CustomTextfield(
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    labelTextStyle2: true,
                    controller: emailController,
                  ),
                  SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    labelTextStyle2: true,
                    controller: firstNameController,
                  ),
                  SizedBox(height: 20),
                  CustomTextfield(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    labelTextStyle2: true,
                    controller: lastNameController,
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
                  CustomTextfield(
                    labelText: 'Country',
                    hintText: 'Nigeria',
                    labelTextStyle2: true,
                    controller: countryController,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value!;
                          });
                        },
                      ),
                      Flexible(
                        child: Text(
                          'Hi superwomen by continuing, you agree to these easy rules to keep us both safe and get you better service',
                          style: TextStyle(fontSize: 13),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Show loading indicator when registration is in progress
                  if (userProvider.isLoading)
                    Center(child: CircularProgressIndicator()),

                  // Show error message if registration failed
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
                      if (!isChecked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please agree to the terms and conditions',
                            ),
                          ),
                        );
                        return;
                      }

                      // Prepare user data for registration
                      final userData = {
                        'email': emailController.text,
                        'firstName': firstNameController.text,
                        'lastName': lastNameController.text,
                        'password': passwordController.text,
                        'country': countryController.text,
                        'termsAccepted': isChecked,
                        'role': 1,
                      };

                      // Call register method from provider
                      await userProvider.register(userData);

                      // Navigate on success
                      if (userProvider.isSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountType(),
                          ),
                        );
                      }
                    },
                    widget: Text(
                      'Sign Up',
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
                        'Already have an account?',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Login',
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
