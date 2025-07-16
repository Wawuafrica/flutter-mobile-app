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
import 'package:wawu_mobile/widgets/custom_snackbar.dart';

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Separate error flags for different providers
  bool _hasShownUserError = false;
  bool _hasShownLocationError = false;
  bool _hasShownLinksError = false;

  // Flag to track if countries have been fetched
  bool _countriesFetched = false;

  @override
  void initState() {
    super.initState();
    // Fetch countries once when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_countriesFetched) {
        context.read<LocationProvider>().fetchCountries();
        _countriesFetched = true;
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildLoadingContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: wawuColors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: wawuColors.grey),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContainer(String text, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: wawuColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Listen for errors from UserProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProvider.hasError &&
              userProvider.errorMessage != null &&
              !_hasShownUserError) {
            CustomSnackBar.show(
              context,
              message: userProvider.errorMessage!,
              isError: true,
            );
            _hasShownUserError = true;
            userProvider.resetState();
          } else if (!userProvider.hasError && _hasShownUserError) {
            _hasShownUserError = false;
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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomIntroBar(text: 'Sign Up'),
                    CustomTextfield(
                      labelText: 'Email Address',
                      hintText: 'Enter your email address',
                      labelTextStyle2: true,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
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
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) {
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
                              !_hasShownLocationError) {
                            CustomSnackBar.show(
                              context,
                              message: locationProvider.errorMessage!,
                              isError: true,
                              actionLabel: 'Retry',
                              onActionPressed: () {
                                locationProvider.fetchCountries();
                              },
                            );
                            _hasShownLocationError = true;
                            locationProvider.clearError();
                          } else if (!locationProvider.hasError &&
                              _hasShownLocationError) {
                            _hasShownLocationError = false;
                          }
                        });

                        // Loading state
                        if (locationProvider.isLoading) {
                          return _buildLoadingContainer('Loading countries...');
                        }

                        // Error state with fallback UI
                        if (locationProvider.hasError) {
                          return _buildErrorContainer(
                            'Failed to load countries',
                            () {
                              locationProvider.fetchCountries();
                            },
                          );
                        }

                        // Empty state
                        if (locationProvider.countries.isEmpty) {
                          return _buildErrorContainer(
                            'No countries available',
                            () {
                              locationProvider.fetchCountries();
                            },
                          );
                        }

                        // Success state
                        final countryOptions = locationProvider.countries;
                        return CustomDropdown<Country>(
                          label: 'Select your country',
                          options: countryOptions,
                          selectedValue: countryOptions.firstWhereOrNull(
                            (c) => c.name == selectedCountry,
                          ),
                          getLabel: (c) => c.name,
                          itemBuilder: (
                            context,
                            Country country,
                            bool isSelected,
                          ) {
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
                              !_hasShownLinksError) {
                            CustomSnackBar.show(
                              context,
                              message: linksProvider.errorMessage!,
                              isError: true,
                              actionLabel: 'Retry',
                              onActionPressed: () {
                                linksProvider.fetchLinks();
                              },
                            );
                            _hasShownLinksError = true;
                            linksProvider.clearError();
                          } else if (!linksProvider.hasError &&
                              _hasShownLinksError) {
                            _hasShownLinksError = false;
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
                    if (userProvider.isLoading)
                      CustomButton(
                        color: wawuColors.buttonPrimary,
                        function: () {},
                        widget: const Center(
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
                          if (!_formKey.currentState!.validate()) {
                            CustomSnackBar.show(
                              context,
                              message:
                                  'Please fill all required fields correctly.',
                              isError: true,
                            );
                            return;
                          }

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
                              isError: true,
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

                          final userData = {
                            'email': emailController.text,
                            'firstName': firstNameController.text,
                            'lastName': lastNameController.text,
                            'password': passwordController.text,
                            'phoneNumber': phoneController.text,
                            'gender': selectedGender,
                            'country': selectedCountry,
                            'termsAccepted': isChecked,
                            'role': 5,
                          };

                          await userProvider.register(userData);

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
