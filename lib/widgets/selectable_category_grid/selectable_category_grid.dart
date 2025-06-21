import 'package:flutter/material.dart';

class SelectableCategoryGrid extends StatefulWidget {
  final List<String> categories;
  final Function(String) onCategorySelected;

  const SelectableCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<SelectableCategoryGrid> createState() => _SelectableCategoryGridState();
}

class _SelectableCategoryGridState extends State<SelectableCategoryGrid> {
  String? selectedCategory;

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final isSelected = category == selectedCategory;

        return GestureDetector(
          onTap: () => _onCategorySelected(category),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color.fromARGB(255, 235, 235, 235),
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 14,
                // fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}
