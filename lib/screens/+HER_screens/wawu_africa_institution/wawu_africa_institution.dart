import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_single_institution/wawu_africa_single_institution.dart';
import 'package:wawu_mobile/utils/error_utils.dart';

class WawuAfricaInstitution extends StatefulWidget {
  const WawuAfricaInstitution({super.key});

  @override
  State<WawuAfricaInstitution> createState() => _WawuAfricaInstitutionState();
}

class _WawuAfricaInstitutionState extends State<WawuAfricaInstitution> {
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
                        message: 'If this problem persists, please contact our support team. We are here to help!',
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
            title: Text('Dynamic'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                SizedBox(height: 10),
                ...categoryProvider.categories.map(
                  (category) => (Column(
                    children: [
                      _buildItem(title: category.name, uuid: category.uuid, 
                      // imageUrl: category.imageUrl
                      ),
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

  Widget _buildItem({required String title, required String uuid, String? imageUrl}) {
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
          MaterialPageRoute(builder: (context) => WawuAfricaSingleInstitution(
            // categoryId: selectedCategory.uuid,
            // categoryName: selectedCategory.name,
          )),
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
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? '',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.category,
                        size: 35,
                        color: Colors.grey,
                      ),
                    );
                  },
                  placeholder: (context, url) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}