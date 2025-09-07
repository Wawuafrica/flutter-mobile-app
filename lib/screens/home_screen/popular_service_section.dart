import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/screens/categories/sub_categories_and_services_screen.dart/sub_categories_and_services.dart';
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';

class PopularServicesSection extends StatelessWidget {
  const PopularServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final List<String> assetPaths = [
      'assets/images/section/programming.png',
      'assets/images/section/photography.png',
      'assets/images/section/sales.png',
    ];

    if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categoryProvider.categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }

    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      scrollDirection: Axis.horizontal,
      itemCount: categoryProvider.categories.take(3).length,
      itemBuilder: (context, index) {
        final category = categoryProvider.categories[index];
        return ImageTextCard(
          function: () {
            categoryProvider.selectCategory(category);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubCategoriesAndServices(),
              ),
            );
          },
          text: category.name,
          asset: assetPaths[index],
        );
      },
    );
  }
}
