import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart'; // Import the ProfileUpdate screen
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/selectable_category_grid/selectable_category_grid.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';

class SubCategorySelection extends StatefulWidget {
  final String categoryId;

  const SubCategorySelection({super.key, required this.categoryId});

  @override
  State<SubCategorySelection> createState() => _SubCategorySelectionState();
}

class _SubCategorySelectionState extends State<SubCategorySelection> {
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      if (categoryProvider.subCategories.isEmpty &&
          !categoryProvider.isLoading) {
        categoryProvider.fetchSubCategories(widget.categoryId);
      }
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        if (categoryProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (categoryProvider.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading subcategories: ${categoryProvider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      categoryProvider.fetchSubCategories(widget.categoryId);
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Contact Support'),
                    onPressed: () {
                      showErrorSupportDialog(
                        context: context,
                        title: 'Contact Support',
                        message:
                            'If this problem persists, please contact our support team. We are here to help!',
                      );
                    },
                  ),
                ],
              ),
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
                        // Ensure the text is safe from null selectedCategory
                        text:
                            categoryProvider.selectedCategory != null
                                ? categoryProvider.selectedCategory!.name
                                : 'Select Subcategory',
                        // If desc is ever needed here, handle it similarly
                        // desc: 'This is the description for ${categoryProvider.selectedCategory?.name ?? 'your selected category'}.',
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
                      if (userProvider.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            userProvider.errorMessage ?? 'An error occurred',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SelectableCategoryGrid(
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
                          // Also store the selected SubCategory object in the CategoryProvider
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a subcategory.'),
                            ),
                          );
                          return;
                        }

                        // Remove the API call here as requested
                        // await userProvider.updateCurrentUserProfile({
                        //   'subcategories': [_selectedSubCategoryId!],
                        // });

                        // Persist onboarding step and subcategory
                        await OnboardingStateService.saveStep('profile_update');
                        await OnboardingStateService.saveSubCategory(
                          _selectedSubCategoryId!,
                        );
                        // Navigate to ProfileUpdate screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateProfile(),
                          ),
                        );
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
