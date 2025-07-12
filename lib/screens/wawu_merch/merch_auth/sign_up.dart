import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/wawu_merch/merch_auth/sign_in.dart';
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_main.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/providers/links_provider.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/models/country.dart';
import 'package:wawu_mobile/providers/location_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpMerch extends StatefulWidget {
  const SignUpMerch({super.key});

  @override
  State<SignUpMerch> createState() => _SignUpMerchState();
}

class _SignUpMerchState extends State<SignUpMerch> {
  bool isChecked = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedCountry;
  String? selectedGender;

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
          appBar: AppBar(),

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
                      // desc: 'Wanna show off your superpower?  Start here.',
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
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      labelTextStyle2: true,
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        // Add validation
                        if (value == null || value.isEmpty) {
                          return 'Phone number cannot be empty';
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
                    Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Replace CustomTextfield with CustomDropdown for country
                    CustomDropdown(
                      options: ['Male', 'Female'],
                      label: 'Select your gender',
                      selectedValue: selectedGender,
                      enableSearch: false,
                      onChanged: (String? value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                      isDisabled: userProvider.isLoading,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, _) {
                        // If not loading, not error, and no data, trigger fetch
                        if (!locationProvider.isLoadingCountries &&
                            locationProvider.errorCountries == null &&
                            locationProvider.countries.isEmpty) {
                          Future.microtask(
                            () => locationProvider.fetchCountries(),
                          );
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: wawuColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('Loading countries...'),
                              ],
                            ),
                          );
                        }
                        if (locationProvider.isLoadingCountries) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: wawuColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('Loading countries...'),
                              ],
                            ),
                          );
                        } else if (locationProvider.errorCountries != null) {
                          return Text(
                            'Error: ${locationProvider.errorCountries}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        final countryOptions = locationProvider.countries;
                        if (countryOptions.isEmpty) {
                          return Text(
                            'No countries available',
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        return CustomDropdown<Country>(
                          label: 'Select your country',
                          options: countryOptions,
                          selectedValue: countryOptions.firstWhereOrNull(
                            (c) => c.name == selectedCountry,
                          ),
                          getLabel: (c) => c.name,
                          itemBuilder: (
                            context,
                            Country country, // CHANGE 'dynamic' TO 'Country'
                            bool isSelected,
                          ) {
                            // No need for 'final c = country as Country;' now
                            // You can directly use 'country' here.
                            return Row(
                              children: [
                                if (country.flag != null &&
                                    country.flag!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: SvgPicture.network(
                                      country.flag!,
                                      width: 24,
                                      height: 18,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 24,
                                                height: 18,
                                                color: Colors.grey,
                                              ),
                                    ),
                                  ),
                                Text(country.name),
                              ],
                            );
                          },
                          onChanged:
                              userProvider.isLoading
                                  ? null
                                  : (Country? country) {
                                    setState(() {
                                      selectedCountry = country?.name;
                                      // selectedState = null;
                                    });
                                    if (country != null && country.id != 0) {
                                      locationProvider.fetchStates(country.id);
                                    }
                                  },
                          isDisabled: userProvider.isLoading,
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Consumer<LinksProvider>(
                      builder: (context, linksProvider, _) {
                        final termsLink =
                            linksProvider.getLinkByName('terms of use')?.link ??
                            '';
                        final privacyLink =
                            linksProvider
                                .getLinkByName('privacy policy')
                                ?.link ??
                            '';
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged:
                                  userProvider.isLoading
                                      ? null
                                      : (value) {
                                        setState(() {
                                          isChecked = value ?? false;
                                        });
                                      },
                            ),
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('I agree to the '),
                                  GestureDetector(
                                    onTap: () async {
                                      if (termsLink.isNotEmpty) {
                                        final uri = Uri.parse(termsLink);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Terms of Use',
                                      style: const TextStyle(
                                        color: wawuColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(' and '),
                                  GestureDetector(
                                    onTap: () async {
                                      if (privacyLink.isNotEmpty) {
                                        final uri = Uri.parse(privacyLink);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Privacy Policy',
                                      style: const TextStyle(
                                        color: wawuColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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

                          if (selectedGender == null ||
                              selectedGender!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select your gender.'),
                                backgroundColor: Colors.red,
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
                            'phoneNumber': phoneController.text,
                            'gender': selectedGender,
                            'country': selectedCountry,
                            'termsAccepted': isChecked,
                            'role':
                                5, // Ensure this role ID is correct as per your backend
                          };

                          await userProvider.register(userData);

                          // Only navigate if the widget is still mounted and registration was successful
                          if (mounted && userProvider.isSuccess) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WawuMerchMain(),
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
                                        builder: (context) => SignInMerch(),
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
