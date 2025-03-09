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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal filter buttons
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.filterOptions.map(_buildFilterButton).toList(),
          ),
        ),

        if (widget.isStyle2) SizedBox(height: 20),
        // Content that stretches to full height
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration:
                  widget.isStyle2
                      ? BoxDecoration(
                        border: Border.all(color: wawuColors.primary),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      )
                      : BoxDecoration(),
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
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Text(filter),
            if (_currentFilter == filter)
              ClipOval(
                child: Container(
                  width: 4,
                  height: 4,
                  color: wawuColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
