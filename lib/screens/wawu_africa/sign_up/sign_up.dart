import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/otp_screen/otp_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_in/sign_in.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';

import 'Countries.dart';

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

  // Replace countryController with selectedCountry string
  String? selectedCountry;

  // Declare services without initialization
  late final ApiService apiService;
  late final AuthService authService;

  @override
  void initState() {
    super.initState();
    // Initialize services in initState
    apiService = ApiService();
    authService = AuthService(apiService: apiService);
  }

  // Add a GlobalKey for the form to manage validation state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
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
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 35.0,
              ),
              child: Form(
                // Wrap with Form widget for validation
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
                      keyboardType:
                          TextInputType.emailAddress, // Add keyboard type
                      validator: (value) {
                        // Add validation
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
                      validator: (value) {
                        // Add validation
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
                      validator: (value) {
                        // Add validation
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
                      validator: (value) {
                        // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) {
                          // Example: minimum password length
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Add label for the country dropdown
                    Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Replace CustomTextfield with CustomDropdown for country
                    CustomDropdown(
                      options: Countries.all,
                      label: 'Select your country',
                      selectedValue: selectedCountry,
                      onChanged: (String? value) {
                        setState(() {
                          selectedCountry = value;
                        });
                      },
                      isDisabled: userProvider.isLoading,
                    ),

                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged:
                              userProvider.isLoading
                                  ? null
                                  : (value) {
                                    // Disable checkbox when loading
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
                    if (userProvider.hasError &&
                        userProvider.errorMessage != null)
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
                      CustomButton(
                        color: wawuColors.buttonPrimary,
                        // textColor: Colors.white,
                        function: () {}, // Empty function when loading
                        widget: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      CustomButton(
                        function: () async {
                          // Validate form fields first
                          if (!_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please fill all required fields correctly.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Validate country selection
                          if (selectedCountry == null ||
                              selectedCountry!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select your country.'),
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
                                backgroundColor:
                                    Colors
                                        .orange, // Differentiate from validation errors
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
                            'country':
                                selectedCountry!, // Use selected country name
                            'termsAccepted': isChecked,
                            'role':
                                1, // Ensure this role ID is correct as per your backend
                          };

                          await userProvider.register(userData);

                          // Only navigate if the widget is still mounted and registration was successful
                          if (mounted && userProvider.isSuccess) {
                            await authService.sendOtp(
                              emailController.text.trim(),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => OtpScreen(
                                      authService: authService,
                                      email: emailController.text,
                                    ),
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
                          onTap:
                              userProvider.isLoading
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignIn(),
                                      ),
                                    );
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
