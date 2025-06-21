import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/category_selection/sub_category_selection.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:collection/collection.dart';
import 'package:wawu_mobile/widgets/selectable_category_grid/selectable_category_grid.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
// import 'package:wawu_mobile/utils/error_utils.dart';

class CategorySelection extends StatefulWidget {
  const CategorySelection({super.key});

  @override
  State<CategorySelection> createState() => _CategorySelectionState();
}

class _CategorySelectionState extends State<CategorySelection> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        categoryProvider.fetchCategories();
      }
    });
  }

  void _toggleSelection(String categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = categoryId;
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
                    'Error loading categories: ${categoryProvider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      categoryProvider.fetchCategories();
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
                currentStep: 'category_selection',
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
                            'Hi ${userProvider.currentUser?.firstName ?? 'there'}',
                        desc:
                            'So, wanna tell us more about your superpower? What makes you tick, basically. This is your initial proposal outlining the value proposition of your expertise to prospective clients.',
                      ),
                      const Text(
                        'Select Your Role',
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
                            categoryProvider.categories
                                .map((category) => category.name)
                                .toList(),
                        onCategorySelected: (categoryName) {
                          final selectedCategory = categoryProvider.categories
                              .firstWhere(
                                (category) => category.name == categoryName,
                              );
                          _toggleSelection(selectedCategory.uuid);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // ... inside your Consumer2 builder ...
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Visibility(
                  visible: _selectedCategoryId != null,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    child: CustomButton(
                      function: () async {
                        // Check if a category is selected
                        if (_selectedCategoryId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a category.'),
                            ),
                          );
                          return; // Exit the function if no category is selected
                        }

                        // We are now sure _selectedCategoryId is not null, so we can use it safely.
                        final String selectedCategoryId = _selectedCategoryId!;

                        // Find the Category object using the selected ID
                        // Import 'package:collection/collection.dart' for firstWhereOrNull
                        final selectedCategory = categoryProvider.categories
                            .firstWhereOrNull(
                              (category) => category.uuid == selectedCategoryId,
                            );

                        // If the selected category UUID doesn't match any existing category (e.g., data refresh)
                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selected category not found. Please try again.',
                              ),
                            ),
                          );
                          return; // Exit the function
                        }

                        // Select the found category in the provider state
                        categoryProvider.selectCategory(selectedCategory);

                        // Persist onboarding step and category
                        await OnboardingStateService.saveStep(
                          'subcategory_selection',
                        );
                        await OnboardingStateService.saveCategory(
                          selectedCategoryId,
                        );

                        // Navigate to the SubCategorySelection screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SubCategorySelection(
                                  categoryId:
                                      selectedCategoryId, // Pass the non-null ID
                                ),
                          ),
                        );

                        // Reset _selectedCategoryId AFTER successful navigation initiation
                        // This ensures the button becomes invisible immediately after tapping 'Continue'
                        setState(() {
                          _selectedCategoryId = null;
                        });
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
