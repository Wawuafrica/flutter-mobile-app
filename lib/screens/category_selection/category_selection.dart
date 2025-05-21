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
  final Set<String> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    // Fetch categories when the screen loads
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        // Show loading indicator while fetching categories
        if (categoryProvider.isLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Show error message if fetching categories failed
        if (categoryProvider.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading categories: ${categoryProvider.errorMessage}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => categoryProvider.fetchCategories(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // Continue button
                  CustomButton(
                    function: () async {
                      if (selectedCategories.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select at least one category',
                            ),
                          ),
                        );
                        return;
                      }

                      // Update user profile with selected categories
                      await userProvider.updateCurrentUserProfile({
                        'categories': selectedCategories.toList(),
                      });

                      if (userProvider.isSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      }
                    },
                    widget: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    color: wawuColors.buttonPrimary,
                    textColor: Colors.white,
                  ),

                  SizedBox(height: 20),
                  CustomIntroBar(
                    text:
                        'Hi ${userProvider.currentUser?.firstName ?? 'there'}',
                    desc:
                        'So, wanna tell us more about your superpower? What makes you tick, basically. This is your initial proposal outlining the value proposition of your expertise to prospective clients.',
                  ),
                  Text(
                    'Select Your Role',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 20),

                  // Continue button
                  CustomButton(
                    function: () async {
                      if (selectedCategories.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select at least one category',
                            ),
                          ),
                        );
                        return;
                      }

                      // Update user profile with selected categories
                      await userProvider.updateCurrentUserProfile({
                        'categories': selectedCategories.toList(),
                      });

                      if (userProvider.isSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      }
                    },
                    widget: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    color: wawuColors.buttonPrimary,
                    textColor: Colors.white,
                  ),

                  SizedBox(height: 20),
                  // Show loading indicator when updating profile
                  if (userProvider.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Show error message if update failed
                  if (userProvider.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        userProvider.errorMessage ?? 'An error occurred',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  StaggeredGrid.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      StaggeredGridTile.count(
                        crossAxisCellCount: 4,
                        mainAxisCellCount: 2,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedCategories.contains('designer')) {
                                selectedCategories.remove('designer');
                              } else {
                                selectedCategories.add('designer');
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: wawuColors.purpleDarkestContainer,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  selectedCategories.contains('designer')
                                      ? Border.all(
                                        color: Colors.blue,
                                        width: 2.0,
                                      )
                                      : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                      StaggeredGridTile.count(
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 2.5,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedCategories.contains('data_analyst')) {
                                selectedCategories.remove('data_analyst');
                              } else {
                                selectedCategories.add('data_analyst');
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            clipBehavior: Clip.hardEdge,
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: wawuColors.secondary,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  selectedCategories.contains('data_analyst')
                                      ? Border.all(
                                        color: Colors.blue,
                                        width: 2.0,
                                      )
                                      : null,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Expanded(
                                  child: Text(
                                    'Data Analyst',
                                    style: TextStyle(
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
                      StaggeredGridTile.count(
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 3,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedCategories.contains('programmer')) {
                                selectedCategories.remove('programmer');
                              } else {
                                selectedCategories.add('programmer');
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            clipBehavior: Clip.hardEdge,
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: wawuColors.purpleDarkContainer,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  selectedCategories.contains('programmer')
                                      ? Border.all(
                                        color: Colors.blue,
                                        width: 2.0,
                                      )
                                      : null,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Expanded(
                                  child: Text(
                                    'Programmer',
                                    style: TextStyle(
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
                      StaggeredGridTile.count(
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 3,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedCategories.contains('marketer')) {
                                selectedCategories.remove('marketer');
                              } else {
                                selectedCategories.add('marketer');
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: wawuColors.purpleContainer,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  selectedCategories.contains('marketer')
                                      ? Border.all(
                                        color: Colors.blue,
                                        width: 2.0,
                                      )
                                      : null,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Expanded(
                                  child: Text(
                                    'Marketer',
                                    style: TextStyle(
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
                      StaggeredGridTile.count(
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 2.5,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: wawuColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MoreCategories(),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Expanded(
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
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
