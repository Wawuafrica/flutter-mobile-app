import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customcheckmark/customcheckmark.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customtextfieldgrid/customtextfieldgrid.dart';

class PackageGridComponent extends StatelessWidget {
  final bool isClient;
  const PackageGridComponent({super.key, this.isClient = false});

  @override
  Widget build(BuildContext context) {
    return isClient
        ? Column(
          children: [
            _buildClientRow(false, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(true, 'Context', 'Package Title'),
            _buildClientRow(false, 'Context', '5 days'),
            _buildClientRow(false, 'Context', '\$0.00'),
          ],
        )
        : Column(
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

  Widget _buildClientRow(bool isCheckbox, String title, String hintText) {
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
                child: Center(child: Icon(Icons.check)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Icon(Icons.check)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Icon(Icons.check)),
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
                child: Center(child: Text(hintText)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(hintText)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                width: 70,
                padding: EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(hintText)),
              ),
            ),
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
