import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customcheckmark/customcheckmark.dart';
import 'package:wawu_mobile/widgets/package_grid_component/customtextfieldgrid/customtextfieldgrid.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class PackageGridComponent extends StatefulWidget {
  final bool isClient;
  final ValueChanged<List<Map<String, dynamic>>>? onPackagesChanged;

  const PackageGridComponent({
    super.key,
    this.isClient = false,
    this.onPackagesChanged,
  });

  @override
  _PackageGridComponentState createState() => _PackageGridComponentState();
}

class _PackageGridComponentState extends State<PackageGridComponent> {
  final List<Map<String, dynamic>> _rows = [
    {'label': 'Package Titles', 'isCheckbox': false, 'controllers': [TextEditingController(), TextEditingController(), TextEditingController()]},
    {'label': 'Responsive Design', 'isCheckbox': true, 'values': [true, true, true]},
    {'label': 'Price (NGN)', 'isCheckbox': false, 'controllers': [TextEditingController(), TextEditingController(), TextEditingController()]},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPackagesChanged?.call(getPackageData());
      debugPrint('PackageGridComponent: Initial packages sent');
    });
  }

  @override
  void didUpdateWidget(PackageGridComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPackagesChanged?.call(getPackageData());
      debugPrint('PackageGridComponent: Packages updated');
    });
  }

  void _addRow({required bool isCheckbox}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Feature'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Feature Name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _rows.add({
                  'label': value.trim(),
                  'isCheckbox': isCheckbox,
                  if (isCheckbox) 'values': [false, false, false] else 'controllers': [TextEditingController(), TextEditingController(), TextEditingController()],
                });
                widget.onPackagesChanged?.call(getPackageData());
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getPackageData() {
    final packages = ['Basic', 'Standard', 'Premium'];
    final List<Map<String, dynamic>> pricing = [];

    for (int i = 0; i < 3; i++) {
      final priceText = _rows.firstWhere((row) => row['label'] == 'Price (NGN)')['controllers'][i].text.trim();
      final package = {
        'package': {
          'name': _rows[0]['controllers'][i].text.trim().isEmpty ? packages[i] : _rows[0]['controllers'][i].text.trim(),
          'description': 'Description for ${packages[i]}',
          'amount': priceText.replaceAll('₦', '').replaceAll(',', ''),
        },
        'features': <Map<String, String>>[],
      };

      for (final row in _rows.skip(1).where((row) => row['label'] != 'Price (NGN)')) {
        final Map<String, String> feature = {
          'name': row['label'],
          'value': row['isCheckbox'] ? (row['values'][i] ? 'yes' : 'no') : (row['controllers'][i].text.trim().isEmpty ? '' : row['controllers'][i].text.trim()),
        };
        (package['features'] as List<Map<String, String>>).add(feature);
      }

      pricing.add(package);
    }

    return pricing;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.isClient) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                function: () => _addRow(isCheckbox: true),
                widget: const Text('Add Checkbox Feature', style: TextStyle(color: Colors.white)),
                color: wawuColors.primary,
              ),
              const SizedBox(width: 10),
              CustomButton(
                function: () => _addRow(isCheckbox: false),
                widget: const Text('Add Input Feature', style: TextStyle(color: Colors.white)),
                color: wawuColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        widget.isClient
            ? Column(
                children: _rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return _buildClientRow(
                    row['isCheckbox'] as bool,
                    row['label'] as String,
                    row['isCheckbox']
                        ? ''
                        : (row['controllers'] as List<TextEditingController>)[0].text.isEmpty
                            ? row['label']
                            : (row['controllers'] as List<TextEditingController>)[0].text,
                  );
                }).toList(),
              )
            : Column(
                children: _rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return _buildRow(
                    row['isCheckbox'] as bool,
                    row['label'] as String,
                    row['isCheckbox'] ? '' : row['label'],
                    row['controllers'] as List<TextEditingController>?,
                    row['values'] as List<bool>?,
                    entry.key,
                  );
                }).toList(),
              ),
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
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(title)),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: const Center(child: Icon(Icons.check)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: const Center(child: Icon(Icons.check)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: const Center(child: Icon(Icons.check)),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                width: 100,
                height: 50,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(title)),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(child: Text(hintText)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(child: Text(hintText)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(child: Text(hintText)),
                ),
              ),
            ],
          );
  }

  Widget _buildRow(bool isCheckbox, String title, String hintText, List<TextEditingController>? controllers, List<bool>? values, int rowIndex) {
    return isCheckbox
        ? Row(
            children: [
              Container(
                width: 100,
                height: 50,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(title)),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: Customcheckmark(
                      isChecked: values![0],
                      onChanged: (val) => setState(() {
                        _rows[rowIndex]['values'][0] = val;
                        widget.onPackagesChanged?.call(getPackageData());
                      }),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: Customcheckmark(
                      isChecked: values![1],
                      onChanged: (val) => setState(() {
                        _rows[rowIndex]['values'][1] = val;
                        widget.onPackagesChanged?.call(getPackageData());
                      }),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: Customcheckmark(
                      isChecked: values![2],
                      onChanged: (val) => setState(() {
                        _rows[rowIndex]['values'][2] = val;
                        widget.onPackagesChanged?.call(getPackageData());
                      }),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                width: 100,
                height: 50,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all()),
                child: Center(child: Text(title)),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: CustomTextfieldGrid(
                      hintText: hintText,
                      controller: controllers![0],
                      keyboardType: title == 'Price (NGN)' ? TextInputType.number : null,
                      onChanged: (_) => widget.onPackagesChanged?.call(getPackageData()),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: CustomTextfieldGrid(
                      hintText: hintText,
                      controller: controllers![1],
                      keyboardType: title == 'Price (NGN)' ? TextInputType.number : null,
                      onChanged: (_) => widget.onPackagesChanged?.call(getPackageData()),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                    child: CustomTextfieldGrid(
                      hintText: hintText,
                      controller: controllers![2],
                      keyboardType: title == 'Price (NGN)' ? TextInputType.number : null,
                      onChanged: (_) => widget.onPackagesChanged?.call(getPackageData()),
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
        for (final controller in row['controllers'] as List<TextEditingController>) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }
}