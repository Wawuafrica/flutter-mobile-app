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

  // Add a GlobalKey for the form to manage validation state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
              child: Form( // Wrap with Form widget for validation
                key: _formKey,
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
                      keyboardType: TextInputType.emailAddress, // Add keyboard type
                      validator: (value) { // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Email cannot be empty';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      labelText: 'First Name',
                      hintText: 'Enter your first name',
                      labelTextStyle2: true,
                      controller: firstNameController,
                      validator: (value) { // Add validation
                        if (value == null || value.isEmpty) {
                          return 'First name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      labelText: 'Last Name',
                      hintText: 'Enter your last name',
                      labelTextStyle2: true,
                      controller: lastNameController,
                      validator: (value) { // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Last name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      labelTextStyle2: true,
                      controller: passwordController,
                      obscureText: true,
                      validator: (value) { // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) { // Example: minimum password length
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      labelText: 'Country',
                      hintText: 'Nigeria',
                      labelTextStyle2: true,
                      controller: countryController,
                      validator: (value) { // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Country cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: userProvider.isLoading ? null : (value) { // Disable checkbox when loading
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

                    // Show error message if registration failed
                    if (userProvider.hasError && userProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          userProvider.errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Conditionally render CircularProgressIndicator or CustomButton
                    if (userProvider.isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(wawuColors.buttonPrimary), // Match your button color
                        ),
                      )
                    else
                      CustomButton(
                        function: () async {
                          // Validate form fields first
                          if (!_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill all required fields correctly.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!isChecked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please agree to the terms and conditions',
                                ),
                                backgroundColor: Colors.orange, // Differentiate from validation errors
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
                            'role': 1, // Ensure this role ID is correct as per your backend
                          };

                          await userProvider.register(userData);

                          // Only navigate if the widget is still mounted and registration was successful
                          if (mounted && userProvider.isSuccess) {
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
                        GestureDetector(
                          onTap: userProvider.isLoading ? null : () { // Disable tap when loading
                            // Navigate to Login screen
                            Navigator.pop(context); // Assuming this navigates back to login
                            // Or use: Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: wawuColors.buttonSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // The 'spacing' property is not available on Row. Use SizedBox for spacing between Flexible widgets.
                      children: [
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color.fromARGB(255, 209, 209, 209),
                          ),
                        ),
                        SizedBox(width: 10), // Spacing
                        Text('Or', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 10), // Spacing
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
                      function: userProvider.isLoading ? null : () {
                        // Handle Google Sign-Up
                      },
                      border: Border.all(
                        color: const Color.fromARGB(255, 216, 216, 216),
                      ),
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [ // Removed spacing as it's not a valid property of Row
                          SvgPicture.asset(
                            'assets/images/svg/google.svg',
                            width: 20,
                            height: 20,
                          ),
                          SizedBox(width: 10), // Spacing
                          Text('Continue with Google'),
                        ],
                      ),
                      color: Colors.white,
                      textColor: Colors.black,
                    ),
                    SizedBox(height: 10),
                    CustomButton(
                      function: userProvider.isLoading ? null : () {
                        // Handle Apple Sign-Up
                      },
                      border: Border.all(
                        color: const Color.fromARGB(255, 216, 216, 216),
                      ),
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [ // Removed spacing
                          SvgPicture.asset(
                            'assets/images/svg/apple.svg',
                            width: 20,
                            height: 20,
                          ),
                          SizedBox(width: 10), // Spacing
                          Text('Continue with Apple'),
                        ],
                      ),
                      color: Colors.white,
                      textColor: Colors.black,
                    ),
                    SizedBox(height: 10),
                    CustomButton(
                      function: userProvider.isLoading ? null : () {
                        // Handle Facebook Sign-Up
                      },
                      border: Border.all(
                        color: const Color.fromARGB(255, 216, 216, 216),
                      ),
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [ // Removed spacing
                          SvgPicture.asset(
                            'assets/images/svg/facebook.svg',
                            width: 20,
                            height: 20,
                          ),
                          SizedBox(width: 10), // Spacing
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
          ),
        );
      },
    );
  }
}