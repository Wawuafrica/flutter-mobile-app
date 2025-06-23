import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> options;
  final String label;
  final String? selectedValue;
  final ValueChanged<String?>? onChanged;
  final Color overlayColor;
  final Color modalBackgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDisabled;
  final bool enableSearch; // New parameter to enable/disable search
  final String searchHint; // Customizable search hint text

  const CustomDropdown({
    super.key,
    required this.options,
    required this.label,
    this.selectedValue,
    this.onChanged,
    this.overlayColor = Colors.black54,
    this.modalBackgroundColor = Colors.white,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.isDisabled = false,
    this.enableSearch = true, // Default to true for search functionality
    this.searchHint = 'Search options...', // Default search hint
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? _internalSelectedValue;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _internalSelectedValue = widget.selectedValue;
    _filteredOptions = widget.options;
  }

  @override
  void didUpdateWidget(covariant CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal selected value if parent's selectedValue changes
    if (widget.selectedValue != oldWidget.selectedValue) {
      _internalSelectedValue = widget.selectedValue;
    }
    // Update filtered options if options list changes
    if (widget.options != oldWidget.options) {
      _filteredOptions = widget.options;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions =
            widget.options
                .where(
                  (option) =>
                      option.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _showCustomDropdown() {
    // Prevent opening if disabled
    if (widget.isDisabled) {
      return;
    }

    // Reset search when opening dropdown
    _searchController.clear();
    _filteredOptions = widget.options;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow the modal to take more space if needed
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(color: widget.overlayColor),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
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
                        // Header
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search bar (conditionally shown)
                        if (widget.enableSearch) ...[
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: widget.searchHint,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setModalState(() {
                                              _filteredOptions = widget.options;
                                            });
                                          },
                                        )
                                        : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setModalState(() {
                                  _filterOptions(value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Options list
                        Flexible(
                          child:
                              _filteredOptions.isEmpty
                                  ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No options found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredOptions.length,
                                    itemBuilder: (context, index) {
                                      return _buildOption(
                                        _filteredOptions[index],
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
          widget.onChanged!(option);
        }
        Navigator.pop(context);
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
            fontWeight:
                _internalSelectedValue == option
                    ? FontWeight.w600
                    : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled ? null : _showCustomDropdown,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isDisabled ? Colors.grey[300]! : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
          color: widget.isDisabled ? Colors.grey[100] : Colors.transparent,
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
                          ? Colors.grey[600]
                          : (_internalSelectedValue != null
                              ? Colors.black
                              : Colors.grey[700]),
                  fontWeight:
                      _internalSelectedValue != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              widget.isDisabled
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: widget.isDisabled ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
