// lib/screens/category_selection/category_selection.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/category_selection/more_categories/more_categories.dart';
import 'package:wawu_mobile/screens/profile/profile_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';

class CategorySelection extends StatefulWidget {
  const CategorySelection({super.key});

  @override
  State<CategorySelection> createState() => _CategorySelectionState();
}

class _CategorySelectionState extends State<CategorySelection> {
  // Changed to hold a single selected category ID, or null if none selected.
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

  // Helper method for single selection logic
  void _toggleSelection(String categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        // If the same category is clicked again, unselect it
        _selectedCategoryId = null;
      } else {
        // Select the new category
        _selectedCategoryId = categoryId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        if (categoryProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => categoryProvider.fetchCategories(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  // Added bottom padding to make space for the floating button
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      CustomIntroBar(
                        text: 'Hi ${userProvider.currentUser?.firstName ?? 'there'}',
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

                      StaggeredGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          // Designer Tile
                          StaggeredGridTile.count(
                            crossAxisCellCount: 4,
                            mainAxisCellCount: 2,
                            child: InkWell(
                              onTap: () => _toggleSelection('designer'), // Call toggle function
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                decoration: BoxDecoration(
                                  color: wawuColors.secondary, // Background color remains fixed
                                  borderRadius: BorderRadius.circular(20),
                                  border: _selectedCategoryId == 'designer' // Apply border if selected
                                      ? Border.all(
                                          color: wawuColors.buttonPrimary, // Primary button color for border
                                          width: 2.0,
                                        )
                                      : null, // No border if not selected
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          SizedBox(height: 20.0),
                                          Text(
                                            'Designer',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/roles/designer.webp',
                                      cacheWidth: 300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Data Analyst Tile
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2,
                            mainAxisCellCount: 2.5,
                            child: InkWell(
                              onTap: () => _toggleSelection('data_analyst'), // Call toggle function
                              child: Container(
                                width: double.infinity,
                                clipBehavior: Clip.hardEdge,
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                decoration: BoxDecoration(
                                  color: wawuColors.secondary, // Background color remains fixed
                                  borderRadius: BorderRadius.circular(20),
                                  border: _selectedCategoryId == 'data_analyst' // Apply border if selected
                                      ? Border.all(
                                          color: wawuColors.buttonPrimary, // Primary button color for border
                                          width: 2.0,
                                        )
                                      : null, // No border if not selected
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20.0),
                                    Expanded(
                                      child: Text(
                                        'Data Analyst',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/roles/analyst.webp',
                                      cacheWidth: 300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Programmer Tile
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2,
                            mainAxisCellCount: 3,
                            child: InkWell(
                              onTap: () => _toggleSelection('programmer'), // Call toggle function
                              child: Container(
                                width: double.infinity,
                                clipBehavior: Clip.hardEdge,
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                decoration: BoxDecoration(
                                  color: wawuColors.purpleDarkContainer, // Background color remains fixed
                                  borderRadius: BorderRadius.circular(20),
                                  border: _selectedCategoryId == 'programmer' // Apply border if selected
                                      ? Border.all(
                                          color: wawuColors.buttonPrimary, // Primary button color for border
                                          width: 2.0,
                                        )
                                      : null, // No border if not selected
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20.0),
                                    Expanded(
                                      child: Text(
                                        'Programmer',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/roles/programmer.webp',
                                      cacheWidth: 300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Marketer Tile
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2,
                            mainAxisCellCount: 3,
                            child: InkWell(
                              onTap: () => _toggleSelection('marketer'), // Call toggle function
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                decoration: BoxDecoration(
                                  color: wawuColors.purpleContainer, // Background color remains fixed
                                  borderRadius: BorderRadius.circular(20),
                                  border: _selectedCategoryId == 'marketer' // Apply border if selected
                                      ? Border.all(
                                          color: wawuColors.buttonPrimary, // Primary button color for border
                                          width: 2.0,
                                        )
                                      : null, // No border if not selected
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20.0),
                                    Expanded(
                                      child: Text(
                                        'Marketer',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/roles/marketer.webp',
                                      cacheWidth: 300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // More Tile (remains unaffected by selection logic)
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2,
                            mainAxisCellCount: 2.5,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: wawuColors.secondary, // Background color remains fixed
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // This is the "More" button, it navigates to another screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MoreCategories(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20.0),
                                    const Expanded(
                                      child: Text(
                                        'More',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/roles/more.webp',
                                      cacheWidth: 300,
                                    ),
                                  ],
                                ),
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

              // Floating "Continue" button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Visibility(
                  // Button is visible only if a category IS selected (_selectedCategoryId is not null)
                  visible: _selectedCategoryId != null,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: CustomButton(
                      function: () async {
                        // The button's visibility already ensures _selectedCategoryId is not null.
                        // This check is a safeguard.
                        if (_selectedCategoryId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one speciality.'),
                            ),
                          );
                          return;
                        }

                        await userProvider.updateCurrentUserProfile({
                          // Pass the single selected ID in a list
                          'categories': [_selectedCategoryId!],
                        });

                        if (userProvider.isSuccess) {
                          // Clear selected category only on successful update
                          setState(() {
                            _selectedCategoryId = null;
                          });
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        } else if (userProvider.hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(userProvider.errorMessage ?? 'Failed to save your specialities.'),
                            ),
                          );
                        }
                        userProvider.resetState(); // Reset provider state after operation
                      },
                      widget: userProvider.isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
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