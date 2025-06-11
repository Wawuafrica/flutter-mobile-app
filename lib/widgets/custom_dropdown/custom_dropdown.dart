import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> options;
  final String label;
  final String? selectedValue; // Uncommented
  final ValueChanged<String?>? onChanged; // Uncommented, made nullable
  final Color overlayColor;
  final Color modalBackgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDisabled; // Added for consistency with previous behavior

  const CustomDropdown({
    super.key,
    required this.options,
    required this.label,
    this.selectedValue, // Uncommented
    this.onChanged, // Uncommented
    this.overlayColor = Colors.black54,
    this.modalBackgroundColor = Colors.white,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.isDisabled = false, // Default to false
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String?
  _internalSelectedValue; // Renamed to avoid conflict with widget.selectedValue

  @override
  void initState() {
    super.initState();
    _internalSelectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(covariant CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal selected value if parent's selectedValue changes
    if (widget.selectedValue != oldWidget.selectedValue) {
      _internalSelectedValue = widget.selectedValue;
    }
  }

  void _showCustomDropdown() {
    if (widget.isDisabled) {
      return; // Do nothing if disabled
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the modal when tapping outside
              },
              child: Container(
                color: widget.overlayColor, // Use the provided overlay color
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
                child: ListView(
                  // mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.options.map((option) => _buildOption(option)),
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
        setState(() {
          _internalSelectedValue = option;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(option); // Call the parent's onChanged callback
        }
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
                _internalSelectedValue == option
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
      onTap:
          widget.isDisabled
              ? null
              : _showCustomDropdown, // Disable tap if isDisabled
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isDisabled ? Colors.grey[300]! : Colors.grey,
          ), // Visual cue for disabled
          borderRadius: BorderRadius.circular(8),
          color:
              widget.isDisabled
                  ? Colors.grey[100]
                  : null, // Background color for disabled
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _internalSelectedValue ?? widget.label,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      widget.isDisabled
                          ? Colors.grey
                          : Colors.black, // Text color for disabled
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}
