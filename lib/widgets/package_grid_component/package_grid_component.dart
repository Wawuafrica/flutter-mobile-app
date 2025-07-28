import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customcheckmark/customcheckmark.dart';

class PackageGridComponent extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const PackageGridComponent({super.key, this.initialData});

  @override
  _PackageGridComponentState createState() => _PackageGridComponentState();
}

class _PackageGridComponentState extends State<PackageGridComponent> {
  late List<Map<String, dynamic>> _rows;

  @override
  void initState() {
    super.initState();
    _rows =
        widget.initialData ??
        [
          {
            'label': 'Package Titles',
            'isCheckbox': false,
            'controllers': [
              TextEditingController(text: 'Basic'),
              TextEditingController(text: 'Standard'),
              TextEditingController(text: 'Premium'),
            ],
          },
          {
            'label': 'Price (NGN)',
            'isCheckbox': false,
            'controllers': [
              TextEditingController(text: '₦0'),
              TextEditingController(text: '₦0'),
              TextEditingController(text: '₦0'),
            ],
          },
        ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          children:
              _rows.asMap().entries.map((entry) {
                final row = entry.value;
                return _buildRow(
                  row['isCheckbox'] as bool,
                  row['label'] as String,
                  row['isCheckbox'] ? '' : row['label'],
                  row['controllers'] as List<TextEditingController>?,
                  row['values'] as List<bool>?,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildRow(
    bool isCheckbox,
    String title,
    String hintText,
    List<TextEditingController>? controllers,
    List<bool>? values,
  ) {
    return isCheckbox
        ? Row(
          children: [
            Container(
              width: 150,
              height: 70,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(border: Border.all()),
              child: Center(child: Text(title)),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Customcheckmark(
                    isChecked: values![0],
                    onChanged: null, // Disable interaction
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Customcheckmark(
                    isChecked: values[1],
                    onChanged: null, // Disable interaction
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Customcheckmark(
                    isChecked: values[2],
                    onChanged: null, // Disable interaction
                  ),
                ),
              ),
            ),
          ],
        )
        : Row(
          children: [
            Container(
              width: 145,
              height: 70,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(border: Border.all()),
              child: Center(child: Text(title)),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Text(
                    controllers![0].text.isEmpty
                        ? hintText
                        : controllers[0].text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Text(
                    controllers[1].text.isEmpty
                        ? hintText
                        : controllers[1].text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 70,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(
                  child: Text(
                    controllers[2].text.isEmpty
                        ? hintText
                        : controllers[2].text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  @override
  void dispose() {
    for (final row in _rows) {
      if (row['controllers'] != null) {
        for (final controller
            in row['controllers'] as List<TextEditingController>) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }
}
