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
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar

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

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    phoneController.dispose(); // Dispose phoneController
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
            // Assuming UserProvider has a resetState() or clearError() method.
            userProvider.resetState(); // Or userProvider.clearError();
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Replace CustomTextfield with CustomDropdown for country
                    CustomDropdown(
                      options: const ['Male', 'Female'],
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
                    const SizedBox(height: 20),
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, _) {
                        // Listen for errors from LocationProvider and display SnackBar
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (locationProvider.hasError &&
                              locationProvider.errorMessage != null &&
                              !_hasShownError) {
                            CustomSnackBar.show(
                              context,
                              message: locationProvider.errorMessage!,
                              isError: true,
                              actionLabel: 'Retry',
                              onActionPressed: () {
                                locationProvider.fetchCountries();
                              },
                            );
                            _hasShownError = true;
                            locationProvider
                                .clearError(); // Assuming resetState or clearError
                          } else if (!locationProvider.hasError &&
                              _hasShownError) {
                            _hasShownError = false;
                          }
                        });

                        // If not loading, not error, and no data, trigger fetch
                        if (!locationProvider.isLoading &&
                            locationProvider.errorMessage == null &&
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
                        if (locationProvider.isLoading) {
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
                        // Removed the inline error Text widget for locationProvider.
                        // Errors are now handled by CustomSnackBar.
                        // else if (locationProvider.errorMessage != null) {
                        //   return Text(
                        //     'Error: ${locationProvider.errorMessage}',
                        //     style: const TextStyle(color: Colors.red),
                        //   );
                        // }
                        final countryOptions = locationProvider.countries;
                        if (countryOptions.isEmpty) {
                          // This is an empty state, not necessarily an error,
                          // unless fetchCountries() failed and set an error.
                          // If there's an error, the SnackBar above will handle it.
                          return const Text(
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
                    const SizedBox(height: 20),
                    Consumer<LinksProvider>(
                      builder: (context, linksProvider, _) {
                        // Listen for errors from LinksProvider and display SnackBar
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (linksProvider.hasError &&
                              linksProvider.errorMessage != null &&
                              !_hasShownError) {
                            CustomSnackBar.show(
                              context,
                              message: linksProvider.errorMessage!,
                              isError: true,
                              actionLabel: 'Retry',
                              onActionPressed: () {
                                linksProvider.fetchLinks();
                              },
                            );
                            _hasShownError = true;
                            linksProvider
                                .clearError(); // Assuming resetState or clearError
                          } else if (!linksProvider.hasError &&
                              _hasShownError) {
                            _hasShownError = false;
                          }
                        });

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
                                        } else {
                                          CustomSnackBar.show(
                                            context,
                                            message:
                                                'Could not open Terms of Use link.',
                                            isError: true,
                                          );
                                        }
                                      } else {
                                        CustomSnackBar.show(
                                          context,
                                          message:
                                              'Terms of Use link is not available.',
                                          isError: true,
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Terms of Use',
                                      style: TextStyle(
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
                                        } else {
                                          CustomSnackBar.show(
                                            context,
                                            message:
                                                'Could not open Privacy Policy link.',
                                            isError: true,
                                          );
                                        }
                                      } else {
                                        CustomSnackBar.show(
                                          context,
                                          message:
                                              'Privacy Policy link is not available.',
                                          isError: true,
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
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
                    const SizedBox(height: 20),

                    // Removed the old inline error Text widget for userProvider.
                    // if (userProvider.hasError &&
                    //     userProvider.errorMessage != null)
                    //   Padding(
                    //     padding: const EdgeInsets.only(bottom: 10.0),
                    //     child: Text(
                    //       userProvider.errorMessage!,
                    //       style: TextStyle(color: Colors.red),
                    //       textAlign: TextAlign.center,
                    //     ),
                    //   ),

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
                            CustomSnackBar.show(
                              context,
                              message:
                                  'Please fill all required fields correctly.',
                              isError: true,
                            );
                            return;
                          }

                          // Validate country selection
                          if (selectedCountry == null ||
                              selectedCountry!.isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please select your country.',
                              isError: true,
                            );
                            return;
                          }

                          if (!isChecked) {
                            CustomSnackBar.show(
                              context,
                              message:
                                  'Please agree to the terms and conditions',
                              isError: true, // Changed to error for consistency
                            );
                            return;
                          }

                          if (selectedGender == null ||
                              selectedGender!.isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please select your gender.',
                              isError: true,
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
                                builder: (context) => const WawuMerchMain(),
                              ),
                            );
                          }
                        },
                        widget: const Text(
                          'Sign Up',
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
                          'Already have an account?',
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
                                        builder:
                                            (context) => const SignInMerch(),
                                      ),
                                    );
                                  },
                          child: const Text(
                            'Login',
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
          ),
        );
      },
    );
  }
}
