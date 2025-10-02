import 'package:cached_network_image/cached_network_image.dart';
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            return Center(
              child: Image.asset(
                'assets/wawuback.png',
                width: 220, // You can adjust the size as needed
                height: 220,
                fit: BoxFit.contain,
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
                      crossAxisSpacing: 5.0,
                      mainAxisSpacing: 5.0,
                      childAspectRatio: 0.85,
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
    BuildContext context,
    sub_category_model.WawuAfricaSubCategory subCategory,
  ) {
    final provider = Provider.of<WawuAfricaProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        // Select the tapped sub-category and navigate to the next screen
        provider.selectSubCategory(subCategory);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WawuAfricaInstitution(),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Use Flexible and AspectRatio to make the image larger and responsive
          Flexible(
            child: AspectRatio(
              aspectRatio: 4 / 3, // Enforces the 4:2 ratio
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: subCategory.imageUrl,
                  // No fixed width/height, it's now controlled by the parent widgets
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SvgPicture.asset(
                    'assets/wawu_svg.svg',
                    fit: BoxFit.contain,
                  ),
                  errorWidget: (context, url, error) => SvgPicture.asset(
                    'assets/wawu_svg.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subCategory.name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}