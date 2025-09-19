import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
// import 'package:wawu_mobile/utils/error_utils.dart'; // This utility might be replaced or integrated
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/selectable_category_grid/selectable_category_grid.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class SubCategorySelection extends StatefulWidget {
  final String categoryId;

  const SubCategorySelection({super.key, required this.categoryId});

  @override
  State<SubCategorySelection> createState() => _SubCategorySelectionState();
}

class _SubCategorySelectionState extends State<SubCategorySelection> {
  String? _selectedSubCategoryId;

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      // Clear existing subcategories to ensure fresh data
      categoryProvider.subCategories.clear();
      // Fetch subcategories for the provided categoryId
      categoryProvider.fetchSubCategories(widget.categoryId);
    });
  }

  void _toggleSelection(String subCategoryId) {
    setState(() {
      if (_selectedSubCategoryId == subCategoryId) {
        _selectedSubCategoryId = null;
      } else {
        _selectedSubCategoryId = subCategoryId;
      }
    });
  }

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        // Listen for errors from CategoryProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (categoryProvider.hasError &&
              categoryProvider.errorMessage != null &&
              !_hasShownError) {
            CustomSnackBar.show(
              context,
              message: categoryProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                categoryProvider.fetchSubCategories(widget.categoryId);
              },
            );
            _hasShownError = true;
            categoryProvider.clearError(); // Clear error state
          } else if (!categoryProvider.hasError && _hasShownError) {
            _hasShownError = false;
          }
        });

        // Listen for errors from UserProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProvider.hasError &&
              userProvider.errorMessage != null &&
              !_hasShownError) {
            CustomSnackBar.show(
              context,
              message: userProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                // Assuming userProvider has a method to refresh user data if needed
                // userProvider.fetchCurrentUser();
              },
            );
            _hasShownError = true;
            userProvider.resetState(); // Clear error state
          } else if (!userProvider.hasError && _hasShownError) {
            _hasShownError = false;
          }
        });

        if (categoryProvider.isLoading &&
            categoryProvider.subCategories.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Display full error screen if subcategory loading failed critically
        if (categoryProvider.hasError &&
            categoryProvider.subCategories.isEmpty &&
            !categoryProvider.isLoading) {
          return Scaffold(
            body: FullErrorDisplay(
              errorMessage:
                  categoryProvider.errorMessage ??
                  'Failed to load subcategories. Please try again.',
              onRetry: () {
                categoryProvider.fetchSubCategories(widget.categoryId);
              },
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'If this problem persists, please contact our support team. We are here to help!',
                );
              },
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              OnboardingProgressIndicator(
                currentStep: 'subcategory_selection',
                steps: const [
                  'account_type',
                  'category_selection',
                  'subcategory_selection',
                  'update_profile',
                  'profile_update',
                  'plan',
                  'payment',
                  'payment_processing',
                  'verify_payment',
                  'disclaimer',
                ],
                stepLabels: const {
                  'account_type': 'Account',
                  'category_selection': 'Category',
                  'subcategory_selection': 'Subcategory',
                  'update_profile': 'Intro',
                  'profile_update': 'Profile',
                  'plan': 'Plan',
                  'payment': 'Payment',
                  'payment_processing': 'Processing',
                  'verify_payment': 'Verify',
                  'disclaimer': 'Disclaimer',
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomIntroBar(
                        text:
                            categoryProvider.selectedCategory != null
                                ? categoryProvider.selectedCategory!.name
                                : 'Select Subcategory',
                      ),
                      const Text(
                        'Select Your Specialty',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      if (userProvider.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      // Removed the old inline error Text widget for userProvider.
                      // if (userProvider.hasError)
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(vertical: 10.0),
                      //     child: Text(
                      //       userProvider.errorMessage ?? 'An error occurred',
                      //       style: const TextStyle(color: Colors.red),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //   ),
                      categoryProvider.subCategories.isEmpty &&
                              !categoryProvider.isLoading &&
                              !categoryProvider.hasError
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Text(
                                'No subcategories available for this category.',
                              ),
                            ),
                          )
                          : SelectableCategoryGrid(
                            categories:
                                categoryProvider.subCategories
                                    .map((subCategory) => subCategory.name)
                                    .toList(),
                            onCategorySelected: (subCategoryName) {
                              final selectedSubCategory = categoryProvider
                                  .subCategories
                                  .firstWhere(
                                    (subCategory) =>
                                        subCategory.name == subCategoryName,
                                  );
                              _toggleSelection(selectedSubCategory.uuid);
                              categoryProvider.selectSubCategory(
                                selectedSubCategory,
                              );
                            },
                          ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Visibility(
                  visible: _selectedSubCategoryId != null,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    child: CustomButton(
                      function: () async {
                        if (_selectedSubCategoryId == null) {
                          CustomSnackBar.show(
                            context,
                            message: 'Please select a subcategory.',
                            isError: true,
                          );
                          return;
                        }

                        final userProvider = Provider.of<UserProvider>(
                          context,
                          listen: false,
                        );
                        final role =
                            userProvider.currentUser?.role?.toLowerCase();
                        if (role == 'buyer') {
                          await OnboardingStateService.saveStep('update_profile');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UpdateProfile(),
                            ),
                          );
                        } else {
                          await OnboardingStateService.saveStep('plan');
                          await OnboardingStateService.saveSubCategory(
                            _selectedSubCategoryId!,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Plan(),
                            ),
                          );
                        }
                      },
                      widget: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      color: wawuColors.buttonPrimary,
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
