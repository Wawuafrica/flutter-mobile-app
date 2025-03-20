import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/selectable_category_grid/selectable_category_grid.dart';

class MoreCategories extends StatelessWidget {
  const MoreCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      'Digital Marketing',
      'Software Developer',
      'Graphic Designer',
      'DevOps Engineer',
      'Make Up Artist',
      'Braider',
      'Baker',
      'Chef',
    ];

    void onCategorySelected(String category) {
      print('Selected category: $category');
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          CustomIntroBar(
            text: 'Hello Mavis Nwaokorie',
            topPadding: false,
            desc:
                'So, wanna tell us more about your superpower? What makes you tick, basically. This is your initial proposal outlining the value proposition of your expertise to prospective clients.',
          ),
          const SizedBox(height: 16),
          Text(
            'More Categories',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 16),
          SelectableCategoryGrid(
            categories: categories,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 16),
          CustomButton(
            function: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfile()),
              );
            },
            widget: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            color: wawuColors.borderPrimary,
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
