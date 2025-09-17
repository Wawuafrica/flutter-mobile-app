import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/wawu_africa_nest.dart' as sub_category_model;
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_institution/wawu_africa_institution.dart';
import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class WawuAfricaSubCategory extends StatefulWidget {
  const WawuAfricaSubCategory({super.key});

  @override
  State<WawuAfricaSubCategory> createState() => _WawuAfricaSubCategoryState();
}

class _WawuAfricaSubCategoryState extends State<WawuAfricaSubCategory> {
  @override
  void initState() {
    super.initState();
    // Fetch sub-categories after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
      final selectedCategoryId = provider.selectedCategory?.id;

      // Ensure a category is selected before fetching
      if (selectedCategoryId != null) {
        // Clear previous sub-categories to avoid showing stale data
        provider.clearSubCategories();
        provider.fetchSubCategories(selectedCategoryId.toString());
      } else {
        // Handle case where no category was selected (e.g., direct navigation)
        // You might want to pop the screen or show an error
        print("Error: No category selected to fetch sub-categories for.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<WawuAfricaProvider>(
          builder: (context, provider, child) {
            // Display the name of the selected category in the AppBar
            return Text(
              provider.selectedCategory?.name ?? 'Sub-Categories',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<WawuAfricaProvider>(
        builder: (context, provider, child) {
          // --- Loading State ---
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Error State ---
          if (provider.hasError && provider.subCategories.isEmpty) {
            return FullErrorDisplay(
              errorMessage:
                  provider.errorMessage ?? 'Failed to load sub-categories.',
              onRetry: () {
                final selectedCategoryId = provider.selectedCategory?.id;
                if (selectedCategoryId != null) {
                  provider.fetchSubCategories(selectedCategoryId.toString());
                }
              },
              onContactSupport: () {
                showErrorSupportDialog(
                  context: context,
                  message:
                      'If the problem persists, please contact our support team.',
                  title: 'Error',
                );
              },
            );
          }

          // --- Empty State ---
          if (provider.subCategories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No Sub-Categories Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There are no sub-categories available in this section yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // --- Success State ---
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: provider.subCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = provider.subCategories[index];
                      return _buildItem(context, subCategory);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildItem(
    BuildContext context, sub_category_model.WawuAfricaSubCategory subCategory) {
  final provider = Provider.of<WawuAfricaProvider>(context, listen: false);

  return GestureDetector(
    onTap: () {
      // Select the tapped sub-category and navigate to the next screen
      provider.selectSubCategory(subCategory);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const WawuAfricaInstitution()),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // This will now work correctly
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Use a larger, more balanced size for the image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SvgPicture.network(
              subCategory.imageUrl,
              width: 50, // CHANGED: Increased size for better visuals
              height: 50, // CHANGED: Increased size for better visuals
              fit: BoxFit.contain,
              // Your errorBuilder logic is good and remains unchanged
              errorBuilder: (context, url, error) {
                return SvgPicture.asset(
                  'assets/wawu_svg.svg',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8), // Slightly reduced spacing
          // REMOVED: The 'Expanded' and 'Center' widgets were removed from here.
          Text(
            subCategory.name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
}