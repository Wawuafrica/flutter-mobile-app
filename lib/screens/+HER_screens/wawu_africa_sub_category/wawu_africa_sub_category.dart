import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_institution/wawu_africa_institution.dart';
import 'package:wawu_mobile/utils/error_utils.dart';

class WawuAfricaSubCategory extends StatefulWidget {
  const WawuAfricaSubCategory({super.key});

  @override
  State<WawuAfricaSubCategory> createState() => _WawuAfricaSubCategoryState();
}

class _WawuAfricaSubCategoryState extends State<WawuAfricaSubCategory> {
  // final bool _isSearchOpen = false;
  // final TextEditingController _searchController = TextEditingController();
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
          title: Text('Sub Cat'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.95, // Adjust this to control item height
                  ),
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryProvider.categories[index];
                    return _buildItem(
                      title: category.name,
                      uuid: category.uuid,
                      // svgUrl: category.svgUrl, // Assuming your category model has svgUrl
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildItem({required String title, required String uuid, String? svgUrl}) {
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
        MaterialPageRoute(builder: (context) => WawuAfricaInstitution()),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 241, 241, 241).withValues(alpha: 30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed position SVG container
          SizedBox(
            height: 70, // Fixed height to keep SVG position consistent
            width: 80,  // Fixed width
            child: _buildSvgIcon(svgUrl),
          ),
          const SizedBox(height: 8), // Fixed spacing
          // Text container with flexible height
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Limit to 2 lines
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper method for SVG with fallback
Widget _buildSvgIcon(String? svgUrl) {
  if (svgUrl == null || svgUrl.isEmpty) {
    return _buildFallbackIcon();
  }

  return SvgPicture.network(
    svgUrl,
    width: 70,
    height: 70,
    fit: BoxFit.contain,
    placeholderBuilder: (context) => Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
        ),
      ),
    ),
    errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
  );
}

// Helper method for fallback SVG
Widget _buildFallbackIcon() {
  return SvgPicture.asset(
    'assets/wawu_svg.svg',
    width: 90,
    height: 70,
    fit: BoxFit.contain,
    placeholderBuilder: (context) => Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.category,
        size: 24,
        color: Colors.grey[600],
      ),
    ),
  );
}

}
