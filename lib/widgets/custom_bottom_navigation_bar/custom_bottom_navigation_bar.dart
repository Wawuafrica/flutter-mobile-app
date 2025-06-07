import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

// New: Define a class for your custom navigation items
class CustomNavItem {
  final String iconPath;
  final String label;

  CustomNavItem({required this.iconPath, required this.label});
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<CustomNavItem> items; // Now accepts a list of CustomNavItem

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items, // Required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(31, 98, 98, 98),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        // Iterate through the provided items to build the navigation
        children: List.generate(items.length, (index) {
          final item = items[index];
          return _buildNavItem(index, item.iconPath, item.label);
        }),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Line at the top for active item
          Container(
            height: 2,
            width: 30,
            color: isSelected ? wawuColors.primary : Colors.transparent,
          ),
          SizedBox(height: 8),
          // SVG Icon
          SvgPicture.asset(
            iconPath,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? wawuColors.primary
                  : const Color.fromARGB(255, 207, 207, 207),
              BlendMode.srcIn, // Use BlendMode.srcIn for coloring SVG
            ),
            height: 20,
          ),
          SizedBox(height: 4),
          // Label
          Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? wawuColors.primary
                      : const Color.fromARGB(255, 207, 207, 207),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
