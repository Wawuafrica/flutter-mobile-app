import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

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
        children: [
          _buildNavItem(0, 'assets/images/svg/home.svg', 'Home'),
          _buildNavItem(1, 'assets/images/svg/blog.svg', 'Blog'),
          _buildNavItem(2, 'assets/images/svg/message.svg', 'Message'),
          _buildNavItem(3, 'assets/images/svg/gigs.svg', 'Gigs'),
          _buildNavItem(4, 'assets/images/svg/settings.svg', 'Settings'),
        ],
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
            color:
                isSelected
                    ? wawuColors.primary
                    : const Color.fromARGB(255, 207, 207, 207),
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
