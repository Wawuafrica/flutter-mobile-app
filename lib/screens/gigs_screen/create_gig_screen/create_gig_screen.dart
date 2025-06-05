import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:wawu_mobile/models/category.dart' as app;
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';
import 'package:wawu_mobile/widgets/upload_pdf/upload_pdf.dart';
import 'package:wawu_mobile/widgets/upload_video/upload_video.dart';

enum FetchType { none, categories, subCategories, services }

class CreateGigScreen extends StatefulWidget {
  const CreateGigScreen({super.key});

  @override
  _CreateGigScreenState createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends State<CreateGigScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _aboutController = TextEditingController();
  final List<XFile> _photos = [];
  XFile? _video;
  XFile? _pdf;
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedServiceId;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _packages = [];
  FetchType _fetchType = FetchType.none;

  // Package Grid State
  final List<Map<String, dynamic>> _rows = [
    {
      'label': 'Package Titles',
      'isCheckbox': false,
      'controllers': [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ],
    },
    {
      'label': 'Responsive Design',
      'isCheckbox': true,
      'values': [true, true, true],
    },
    {
      'label': 'Price (NGN)',
      'isCheckbox': false,
      'controllers': [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ],
    },
  ];

  // FAQ State
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _fetchType = FetchType.categories);
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      _updatePackages();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _keywordsController.dispose();
    _aboutController.dispose();
    _questionController.dispose();
    _answerController.dispose();
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

  void _updatePackages() {
    final packages = ['Basic', 'Standard', 'Premium'];
    final List<Map<String, dynamic>> pricing = [];

    for (int i = 0; i < 3; i++) {
      final priceText =
          _rows
              .firstWhere(
                (row) => row['label'] == 'Price (NGN)',
              )['controllers'][i]
              .text
              .trim();
      final package = {
        'package': {
          'name':
              _rows
                      .firstWhere(
                        (row) => row['label'] == 'Package Titles',
                      )['controllers'][i]
                      .text
                      .trim()
                      .isEmpty
                  ? packages[i]
                  : _rows
                      .firstWhere(
                        (row) => row['label'] == 'Package Titles',
                      )['controllers'][i]
                      .text
                      .trim(),
          'description': 'Description for ${packages[i]}',
          'amount': priceText.replaceAll('₦', '').replaceAll(',', ''),
        },
        'features': <Map<String, String>>[],
      };

      for (final row in _rows
          .skip(1)
          .where((row) => row['label'] != 'Price (NGN)')) {
        final Map<String, String> feature = {
          'name': row['label'],
          'value':
              row['isCheckbox']
                  ? (row['values'][i] ? 'yes' : 'no')
                  : (row['controllers'][i].text.trim().isEmpty
                      ? ''
                      : row['controllers'][i].text.trim()),
        };
        (package['features'] as List<Map<String, String>>).add(feature);
      }

      pricing.add(package);
    }

    setState(() => _packages = pricing);
  }

  void _addPackageRow({required bool isCheckbox}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Feature'),
            content: TextField(
              decoration: const InputDecoration(labelText: 'Feature Name'),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    _rows.add({
                      'label': value.trim(),
                      'isCheckbox': isCheckbox,
                      if (isCheckbox)
                        'values': [false, false, false]
                      else
                        'controllers': [
                          TextEditingController(),
                          TextEditingController(),
                          TextEditingController(),
                        ],
                    });
                    _updatePackages();
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

  void _addFaq() {
    if (_questionController.text.trim().isNotEmpty &&
        _answerController.text.trim().isNotEmpty) {
      setState(() {
        _faqs.add({
          'Question': _questionController.text.trim(),
          'Answer': _answerController.text.trim(),
        });
        _questionController.clear();
        _answerController.clear();
      });
    }
  }

  Future<void> _createGig() async {
    if (_isSubmitting) return;

    final gigProvider = Provider.of<GigProvider>(context, listen: false);

    // Validation
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _keywordsController.text.trim().isEmpty ||
        _aboutController.text.trim().isEmpty ||
        _photos.length < 3 ||
        _selectedServiceId == null ||
        _packages.any((pkg) => pkg['package']['amount'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields, upload at least 3 photos, and set prices',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating your gig...\nThis may take a few minutes.'),
                ],
              ),
            ),
      );

      // Create FormData
      final formData = FormData();

      // Add text fields
      formData.fields.add(MapEntry('title', _titleController.text.trim()));
      formData.fields.add(
        MapEntry('description', _descriptionController.text.trim()),
      );
      formData.fields.add(MapEntry('about', _aboutController.text.trim()));
      formData.fields.add(
        MapEntry('keywords', _keywordsController.text.trim()),
      );
      formData.fields.add(MapEntry('services[1]', _selectedServiceId!));

      // Add photo files
      print('Processing ${_photos.length} photos...');
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        print('Photo ${i + 1} path: ${photo.path}');

        // Add fileName field for each photo
        formData.fields.add(
          MapEntry('asset[photos][${i + 1}][fileName]', photo.name),
        );

        if (photo.path.startsWith('blob:')) {
          // Handle blob URLs by reading bytes
          print('Handling photo ${photo.name} as blob URL.');
          final bytes = await photo.readAsBytes();
          formData.files.add(
            MapEntry(
              'asset[photos][${i + 1}][file]',
              MultipartFile.fromBytes(
                bytes,
                filename: photo.name,
                contentType: MediaType('image', photo.name.split('.').last),
              ),
            ),
          );
        } else {
          // Handle local file paths
          final file = File(photo.path);
          if (!file.existsSync()) {
            print(
              'Error: Photo ${photo.name} not found at path: ${photo.path}',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Photo "${photo.name}" could not be found. Please re-select.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
            setState(() => _isSubmitting = false);
            return;
          }

          final fileSize = await file.length();
          print('Photo ${i + 1} size: ${fileSize / (1024 * 1024)} MB');

          if (fileSize > 5 * 1024 * 1024) {
            print('Warning: Image ${photo.name} is larger than 5MB');
          }

          formData.files.add(
            MapEntry(
              'asset[photos][${i + 1}][file]',
              await MultipartFile.fromFile(
                photo.path,
                filename: photo.name,
                contentType: MediaType('image', photo.name.split('.').last),
              ),
            ),
          );
        }
      }

      // Add video file if exists
      if (_video != null) {
        formData.fields.add(MapEntry('asset[video][fileName]', _video!.name));

        if (_video!.path.startsWith('blob:')) {
          final bytes = await _video!.readAsBytes();
          formData.files.add(
            MapEntry(
              'asset[video][file]',
              MultipartFile.fromBytes(
                bytes,
                filename: _video!.name,
                contentType: MediaType('video', _video!.name.split('.').last),
              ),
            ),
          );
        } else {
          final videoFile = File(_video!.path);
          if (!videoFile.existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Video could not be found. Please re-select.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
            setState(() => _isSubmitting = false);
            return;
          }

          final videoSize = await videoFile.length();
          print('Video size: ${videoSize / (1024 * 1024)} MB');

          if (videoSize > 50 * 1024 * 1024) {
            print('Warning: Video is larger than 50MB, this may take a while');
          }

          formData.files.add(
            MapEntry(
              'asset[video][file]',
              await MultipartFile.fromFile(
                _video!.path,
                filename: _video!.name,
                contentType: MediaType('video', _video!.name.split('.').last),
              ),
            ),
          );
        }
      }

      // Add PDF file if exists
      if (_pdf != null) {
        formData.fields.add(MapEntry('asset[pdf][fileName]', _pdf!.name));

        if (_pdf!.path.startsWith('blob:')) {
          final bytes = await _pdf!.readAsBytes();
          formData.files.add(
            MapEntry(
              'asset[pdf][file]',
              MultipartFile.fromBytes(
                bytes,
                filename: _pdf!.name,
                contentType: MediaType('application', 'pdf'),
              ),
            ),
          );
        } else {
          final pdfFile = File(_pdf!.path);
          if (!pdfFile.existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: PDF could not be found. Please re-select.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
            setState(() => _isSubmitting = false);
            return;
          }

          formData.files.add(
            MapEntry(
              'asset[pdf][file]',
              await MultipartFile.fromFile(
                _pdf!.path,
                filename: _pdf!.name,
                contentType: MediaType('application', 'pdf'),
              ),
            ),
          );
        }
      }

      // Add pricing data
      for (int i = 0; i < _packages.length; i++) {
        final pkg = _packages[i];
        formData.fields.add(
          MapEntry('pricing[${i + 1}][package][name]', pkg['package']['name']),
        );
        formData.fields.add(
          MapEntry(
            'pricing[${i + 1}][package][description]',
            pkg['package']['description'],
          ),
        );
        formData.fields.add(
          MapEntry(
            'pricing[${i + 1}][package][amount]',
            pkg['package']['amount'],
          ),
        );

        for (int j = 0; j < pkg['features'].length; j++) {
          formData.fields.add(
            MapEntry(
              'pricing[${i + 1}][features][${j + 1}][name]',
              pkg['features'][j]['name'],
            ),
          );
          formData.fields.add(
            MapEntry(
              'pricing[${i + 1}][features][${j + 1}][value]',
              pkg['features'][j]['value'],
            ),
          );
        }
      }

      // Add FAQ data
      for (int i = 0; i < _faqs.length; i++) {
        formData.fields.add(
          MapEntry('faq[${i + 1}][question]', _faqs[i]['Question']),
        );
        formData.fields.add(
          MapEntry('faq[${i + 1}][answer]', _faqs[i]['Answer']),
        );
      }

      // Call the API
      final gig = await gigProvider.createGig(formData);

      // Close progress dialog
      Navigator.of(context).pop();

      setState(() => _isSubmitting = false);

      if (gig != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gig created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create gig. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      // Close progress dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      setState(() => _isSubmitting = false);

      String errorMessage = 'Failed to create gig';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage =
              'Connection timeout. Please check your internet connection and try again.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage =
              'Upload timeout. Your files might be too large. Try reducing file sizes.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Server response timeout. The server is taking too long to process your request.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Network connection error. Please check your network connection.';
          break;
        case DioExceptionType.badResponse:
          errorMessage =
              'Server error (${e.response?.statusCode}). Please try again later.';
          break;
        default:
          errorMessage = 'An unexpected error occurred. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Close progress dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      setState(() => _isSubmitting = false);

      print('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildLoadingContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: wawuColors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: wawuColors.grey),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid() {
    return Column(
      children: [
        // Button row - fixed layout
        Row(
          children: [
            Expanded(
              child: CustomButton(
                function: () => _addPackageRow(isCheckbox: true),
                widget: const Text(
                  'Add Checkbox Feature',
                  style: TextStyle(color: Colors.white),
                ),
                color: wawuColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                function: () => _addPackageRow(isCheckbox: false),
                widget: const Text(
                  'Add Input Feature',
                  style: TextStyle(color: Colors.white),
                ),
                color: wawuColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Package table with proper constraints
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              children: [
                // Header row
                _buildHeaderRow(),
                // Data rows
                ..._rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return _buildPackageRow(
                    isCheckbox: row['isCheckbox'] as bool,
                    title: row['label'] as String,
                    hintText: row['isCheckbox'] ? '' : row['label'],
                    controllers:
                        row['controllers'] as List<TextEditingController>?,
                    values: row['values'] as List<bool>?,
                    rowIndex: entry.key,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          width: 120,
          height: 40,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Text(
              'Feature',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 40,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Text(
              'Basic',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 40,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Text(
              'Standard',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 40,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Text(
              'Premium',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageRow({
    required bool isCheckbox,
    required String title,
    required String hintText,
    List<TextEditingController>? controllers,
    List<bool>? values,
    required int rowIndex,
  }) {
    return Row(
      children: [
        Container(
          width: 120,
          height: 50,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        ...List.generate(
          3,
          (index) => Container(
            width: 100,
            height: 50,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Center(
              child:
                  isCheckbox
                      ? Checkbox(
                        value: values![index],
                        onChanged:
                            (val) => setState(() {
                              _rows[rowIndex]['values'][index] = val ?? false;
                              _updatePackages();
                            }),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: controllers![index],
                          keyboardType:
                              title == 'Price (NGN)'
                                  ? TextInputType.number
                                  : null,
                          decoration: InputDecoration(
                            hintText: hintText,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            hintStyle: const TextStyle(fontSize: 10),
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (_) => _updatePackages(),
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqSection() {
    return Column(
      children: [
        if (_faqs.isNotEmpty) ...[
          ..._faqs.asMap().entries.map((entry) {
            final faq = entry.value;
            return Container(
              key: ValueKey('faq_${entry.key}'),
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 10.0),
              decoration: BoxDecoration(
                color: wawuColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq['Question']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          faq['Answer']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _faqs.removeAt(entry.key)),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
        CustomTextfield(
          hintText: 'Add Question',
          labelTextStyle2: true,
          controller: _questionController,
        ),
        const SizedBox(height: 10),
        CustomTextfield(
          hintText: 'Add Answer',
          labelTextStyle2: true,
          controller: _answerController,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            function: _addFaq,
            widget: const Text(
              'Add FAQ',
              style: TextStyle(color: Colors.white),
            ),
            color: wawuColors.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.hasError && _fetchType == FetchType.categories) {
          return Scaffold(
            appBar: AppBar(title: const Text('Create A New Gig')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryProvider.errorMessage ??
                        'Failed to load categories',
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    function: () {
                      setState(() => _fetchType = FetchType.categories);
                      categoryProvider.fetchCategories();
                    },
                    widget: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: wawuColors.purpleDarkContainer,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Create A New Gig')),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const CustomIntroText(text: 'Category & Service'),
                  const SizedBox(height: 10),
                  _fetchType == FetchType.categories &&
                          categoryProvider.isLoading
                      ? _buildLoadingContainer('Loading Categories...')
                      : CustomDropdown(
                        key: ValueKey(
                          'category_dropdown_${categoryProvider.categories.length}',
                        ),
                        options:
                            categoryProvider.categories
                                .map((c) => c.name.toString())
                                .toList(),
                        label: 'Select Category',
                        selectedValue:
                            _selectedCategoryId != null
                                ? categoryProvider.categories
                                    .firstWhere(
                                      (c) => c.uuid == _selectedCategoryId,
                                      orElse:
                                          () => app.CategoryModel(
                                            uuid: '',
                                            name: '',
                                          ),
                                    )
                                    .name
                                    .toString()
                                : null,
                        onChanged: (value) {
                          if (value != null) {
                            final category = categoryProvider.categories
                                .firstWhere(
                                  (c) => c.name.toString() == value,
                                  orElse:
                                      () =>
                                          app.CategoryModel(uuid: '', name: ''),
                                );
                            if (category.uuid.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                setState(() {
                                  _selectedCategoryId = category.uuid;
                                  _selectedSubCategoryId = null;
                                  _selectedServiceId = null;
                                  _fetchType = FetchType.subCategories;
                                });
                                debugPrint(
                                  'Fetching subcategories for category: ${category.uuid}',
                                );
                                await categoryProvider.fetchSubCategories(
                                  category.uuid,
                                );
                              });
                            }
                          }
                        },
                      ),
                  const SizedBox(height: 10),
                  if (_selectedCategoryId != null)
                    _fetchType == FetchType.subCategories &&
                            categoryProvider.isLoading
                        ? _buildLoadingContainer('Loading Subcategories...')
                        : CustomDropdown(
                          key: ValueKey(
                            'subcategory_dropdown_${categoryProvider.subCategories.length}',
                          ),
                          options:
                              categoryProvider.subCategories
                                  .map((sc) => sc.name.toString())
                                  .toList(),
                          label: 'Select Subcategory',
                          selectedValue:
                              _selectedSubCategoryId != null
                                  ? categoryProvider.subCategories
                                      .firstWhere(
                                        (sc) =>
                                            sc.uuid == _selectedSubCategoryId,
                                        orElse:
                                            () => app.SubCategory(
                                              uuid: '',
                                              name: '',
                                            ),
                                      )
                                      .name
                                      .toString()
                                  : null,
                          onChanged: (value) {
                            if (value != null) {
                              final subCategory = categoryProvider.subCategories
                                  .firstWhere(
                                    (sc) => sc.name.toString() == value,
                                    orElse:
                                        () =>
                                            app.SubCategory(uuid: '', name: ''),
                                  );
                              if (subCategory.uuid.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) async {
                                  setState(() {
                                    _selectedSubCategoryId = subCategory.uuid;
                                    _selectedServiceId = null;
                                    _fetchType = FetchType.services;
                                  });
                                  debugPrint(
                                    'Fetching services for subcategory: ${subCategory.uuid}',
                                  );
                                  await categoryProvider.fetchServices(
                                    subCategory.uuid,
                                  );
                                });
                              }
                            }
                          },
                        ),
                  const SizedBox(height: 10),
                  if (_selectedSubCategoryId != null)
                    _fetchType == FetchType.services &&
                            categoryProvider.isLoading
                        ? _buildLoadingContainer('Loading Services...')
                        : CustomDropdown(
                          key: ValueKey(
                            'service_dropdown_${categoryProvider.services.length}',
                          ),
                          options:
                              categoryProvider.services
                                  .map((s) => s.name.toString())
                                  .toList(),
                          label: 'Select Service',
                          selectedValue:
                              _selectedServiceId != null
                                  ? categoryProvider.services
                                      .firstWhere(
                                        (s) => s.uuid == _selectedServiceId,
                                        orElse:
                                            () =>
                                                app.Service(uuid: '', name: ''),
                                      )
                                      .name
                                      .toString()
                                  : null,
                          onChanged: (value) {
                            if (value != null) {
                              final service = categoryProvider.services
                                  .firstWhere(
                                    (s) => s.name.toString() == value,
                                    orElse:
                                        () => app.Service(uuid: '', name: ''),
                                  );
                              if (service.uuid.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    _selectedServiceId = service.uuid;
                                    _fetchType = FetchType.none;
                                  });
                                  debugPrint(
                                    'Selected service: ${service.uuid}',
                                  );
                                });
                              }
                            }
                          },
                        ),
                  const SizedBox(height: 20),
                  const CustomIntroText(text: 'Title & Details'),
                  const SizedBox(height: 10),
                  CustomTextfield(
                    labelText: 'Title',
                    controller: _titleController,
                  ),
                  const SizedBox(height: 10),
                  CustomTextfield(
                    hintText: 'Description',
                    labelTextStyle2: true,
                    maxLines: true,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 10),
                  CustomTextfield(
                    labelText: 'Keywords',
                    controller: _keywordsController,
                  ),
                  const SizedBox(height: 10),
                  CustomTextfield(
                    hintText: 'About this gig',
                    labelTextStyle2: true,
                    maxLines: true,
                    controller: _aboutController,
                  ),
                  const SizedBox(height: 40),
                  const CustomIntroText(text: 'Assets'),
                  const SizedBox(height: 20),
                  const Text('Add at Least 3 Photos'),
                  const SizedBox(height: 20),
                  UploadImage(
                    labelText: 'Upload Image',
                    onImageChanged: (file) {
                      setState(() {
                        if (file != null) {
                          _photos.add(file);
                        }
                      });
                    },
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._photos.asMap().entries.map(
                      (entry) => Container(
                        key: ValueKey('photo_${entry.key}'),
                        margin: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => setState(
                                    () => _photos.removeAt(entry.key),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Upload a Video (Optional)'),
                  const SizedBox(height: 10),
                  UploadVideo(
                    labelText: 'Upload a Video',
                    onVideoChanged: (file) => setState(() => _video = file),
                  ),
                  if (_video != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text(_video!.name)),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _video = null),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Upload a PDF (Optional)'),
                  const SizedBox(height: 10),
                  UploadPdf(
                    labelText: 'Upload a PDF',
                    onPdfChanged: (file) => setState(() => _pdf = file),
                  ),
                  if (_pdf != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text(_pdf!.name)),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _pdf = null),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                  const CustomIntroText(text: 'Packages'),
                  const SizedBox(height: 20),
                  _buildPackageGrid(),
                  const SizedBox(height: 40),
                  const CustomIntroText(text: 'FAQ'),
                  const SizedBox(height: 10),
                  _buildFaqSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          floatingActionButton: GestureDetector(
            onTap: _isSubmitting ? null : _createGig,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: wawuColors.purpleContainer,
                shape: BoxShape.circle,
              ),
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(Icons.done, color: Colors.white, size: 20),
            ),
          ),
        );
      },
    );
  }
}
