import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/screens/categories/sub_categories_and_services_screen.dart/sub_categories_and_services.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
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
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
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
          appBar: AppBar(
            title: Text('Categories'),
            // actions: [
            //   Container(
            //     decoration: BoxDecoration(
            //       color: wawuColors.primary.withAlpha(30),
            //       shape: BoxShape.circle,
            //     ),
            //     margin: EdgeInsets.only(right: 10),
            //     height: 36,
            //     width: 36,
            //     child: IconButton(
            //       icon: Icon(Icons.search, size: 17, color: wawuColors.primary),
            //       onPressed: () {
            //         setState(() {
            //           _isSearchOpen = !_isSearchOpen;
            //         });
            //       },
            //     ),
            //   ),
            // ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                // _buildInPageSearchBar(),
                SizedBox(height: 10),
                ...categoryProvider.categories.map(
                  (category) => (Column(
                    children: [
                      _buildItem(title: category.name, uuid: category.uuid),
                      SizedBox(height: 10),
                    ],
                  )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem({required String title, required String uuid}) {
    CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context);
    return GestureDetector(
      onTap: () {
        final selectedCategory = categoryProvider.categories.firstWhere(
          (category) => category.name == title,
        );
        _toggleSelection(selectedCategory.uuid);
        categoryProvider.selectCategory(selectedCategory);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ServiceDetailed()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                // fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildInPageSearchBar() {
  //   return AnimatedContainer(
  //     duration: Duration(milliseconds: 200),
  //     curve: Curves.ease,
  //     height: _isSearchOpen ? 55 : 0,
  //     child: ClipRRect(
  //       child: SizedBox(
  //         height: _isSearchOpen ? 55 : 0,
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
  //           child:
  //               _isSearchOpen
  //                   ? TextField(
  //                     controller: _searchController,
  //                     decoration: InputDecoration(
  //                       hintText: "Search...",
  //                       hintStyle: TextStyle(fontSize: 12),
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                       filled: true,
  //                       fillColor: wawuColors.primary.withAlpha(30),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: BorderSide(
  //                           color: wawuColors.primary.withAlpha(60),
  //                         ),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                         borderSide: BorderSide(color: wawuColors.primary),
  //                       ),
  //                     ),
  //                   )
  //                   : null,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
