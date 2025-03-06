import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> options;
  final String label;
  // final String? selectedValue;
  // final ValueChanged<String?> onChanged; // Callback when an option is selected
  final Color overlayColor;
  final Color modalBackgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CustomDropdown({
    super.key,
    required this.options,
    required this.label,
    // this.selectedValue,
    // required this.onChanged,
    this.overlayColor = Colors.black54,
    this.modalBackgroundColor = Colors.white,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedValue;

  void _showCustomDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Make the modal background transparent
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the modal when tapping outside
              },
              child: Container(
                color: Colors.transparent, // Use the provided overlay color
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.modalBackgroundColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(widget.borderRadius),
                  ),
                ),
                padding: widget.padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.options
                        .map((option) => _buildOption(option))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(String option) {
    return InkWell(
      onTap: () {
        // widget.onChanged(option);
        setState(() {
          selectedValue = option;
        });
        Navigator.pop(context); // Close the modal after selection
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 16,
            color:
                selectedValue == option
                    ? wawuColors.buttonPrimary
                    : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCustomDropdown,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                selectedValue ?? widget.label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}
