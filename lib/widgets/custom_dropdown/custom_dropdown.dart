import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

typedef DropdownItemBuilder<T> =
    Widget Function(BuildContext context, T item, bool isSelected);

class CustomDropdown<T> extends StatefulWidget {
  final List<T> options;
  final String label;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final Color overlayColor;
  final Color modalBackgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDisabled;
  final bool enableSearch;
  final String searchHint;
  final DropdownItemBuilder<T>? itemBuilder;
  final String Function(T)? getLabel;

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
    this.enableSearch = true,
    this.searchHint = 'Search options...',
    this.itemBuilder,
    this.getLabel,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  T? _internalSelectedValue;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _internalSelectedValue = widget.selectedValue;
    _filteredOptions = widget.options;
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _internalSelectedValue = widget.selectedValue;
    }
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
        if (widget.getLabel != null) {
          _filteredOptions =
              widget.options
                  .where(
                    (option) => widget.getLabel!(option).toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
        } else {
          _filteredOptions =
              widget.options
                  .where(
                    (option) => option.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
        }
      }
    });
  }

  void _showCustomDropdown() {
    if (widget.isDisabled) {
      return;
    }
    _searchController.clear();
    _filteredOptions = widget.options;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                                      final option = _filteredOptions[index];
                                      return _buildOption(option);
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

  Widget _buildOption(T option) {
    final isSelected = _internalSelectedValue == option;
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
        child:
            widget.itemBuilder != null
                ? widget.itemBuilder!(context, option, isSelected)
                : Text(
                  widget.getLabel != null
                      ? widget.getLabel!(option)
                      : option.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? wawuColors.buttonPrimary : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
              child:
                  widget.itemBuilder != null && _internalSelectedValue != null
                      ? widget.itemBuilder!(
                        context,
                        _internalSelectedValue!,
                        true,
                      )
                      : Text(
                        _internalSelectedValue != null
                            ? (widget.getLabel != null
                                ? widget.getLabel!(_internalSelectedValue!)
                                : _internalSelectedValue.toString())
                            : widget.label,
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
