import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class UploadPdf extends StatelessWidget {
  final String labelText;
  final ValueChanged<XFile?> onPdfChanged;

  const UploadPdf({
    super.key,
    required this.labelText,
    required this.onPdfChanged,
  });

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final xFile = XFile(file.path!);
        onPdfChanged(xFile);
      } else {
        onPdfChanged(null);
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      onPdfChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      function: _pickPdf,
      widget: Text(
        labelText,
        style: const TextStyle(color: Colors.white),
      ),
      color: wawuColors.primary,
    );
  }
}