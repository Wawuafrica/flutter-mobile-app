import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customcheckmark/customcheckmark.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customtextfieldgrid/customtextfieldgrid.dart';

class PackageGridComponent extends StatelessWidget {
  const PackageGridComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(false, 'Context', 'Package Title'),
        _buildRow(false, 'Context', 'Package Title'),
        _buildRow(true, 'Context', 'Package Title'),
        _buildRow(true, 'Context', 'Package Title'),
        _buildRow(true, 'Context', 'Package Title'),
        _buildRow(true, 'Context', ''),
        _buildRow(false, 'Context', '\$0.00'),
        _buildRow(false, 'Context', '\$0.00'),
      ],
    );
  }

  Widget _buildRow(bool isCheckbox, String title, String hintText) {
    return isCheckbox
        ? Row(
          children: [
            Container(
              width: 100,
              height: 50,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(border: Border.all()),
              child: Center(child: Text(title)),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customcheckmark()),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customcheckmark()),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customcheckmark()),
              ),
            ),
          ],
        )
        : Row(
          children: [
            Container(
              width: 100,
              height: 50,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(border: Border.all()),
              child: Center(child: Text(title)),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customtextfieldgrid(hintText: hintText)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customtextfieldgrid(hintText: hintText)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Customtextfieldgrid(hintText: hintText)),
              ),
            ),
          ],
        );
  }
}
