import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class FilterableWidgetList extends StatefulWidget {
  final List<Map<String, String>> widgets;
  final List<String> filterOptions;
  final bool isStyle2;
  final Widget Function(Map<String, String> widgetData) itemBuilder;

  const FilterableWidgetList({
    super.key,
    required this.widgets,
    required this.filterOptions,
    required this.itemBuilder,
    this.isStyle2 = true,
  });

  @override
  FilterableWidgetListState createState() => FilterableWidgetListState();
}

class FilterableWidgetListState extends State<FilterableWidgetList> {
  String _currentFilter = 'All';

  List<Map<String, String>> get _filteredWidgets {
    return _currentFilter == 'All'
        ? widget.widgets
        : widget.widgets.where((w) => w['category'] == _currentFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    // Ensure 'All' is always the first option if you want it
    if (!widget.filterOptions.contains('All')) {
      widget.filterOptions.insert(0, 'All');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal filter buttons
        SizedBox(
          height: 35, // Slightly increased height for button style
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.filterOptions.length,
            itemBuilder: (context, index) {
              final filter = widget.filterOptions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0), // Spacing between buttons
                child: _buildFilterButton(filter),
              );
            },
          ),
        ),

        // Added consistent spacing after filters, removing `isStyle2` dependency here
        const SizedBox(height: 20),

        // Content that stretches to full height
        LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: widget.isStyle2 ? BoxDecoration() : BoxDecoration(),
            child: Column(
              spacing: 10.0,
              children: [
                SizedBox(height: 0),
                ..._filteredWidgets.map((data) => widget.itemBuilder(data)),
                SizedBox(height: 0),
              ],
            ),
          );
        },
                ),
      ],
    );
  }

  Widget _buildFilterButton(String filter) {
    final bool isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? wawuColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}