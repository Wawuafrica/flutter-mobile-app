import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class UploadVideo extends StatelessWidget {
  final String labelText;
  final ValueChanged<XFile?> onVideoChanged;

  const UploadVideo({
    super.key,
    required this.labelText,
    required this.onVideoChanged,
  });

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      onVideoChanged(video);
    } catch (e) {
      debugPrint('Error picking video: $e');
      onVideoChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      function: _pickVideo,
      widget: Text(
        labelText,
        style: const TextStyle(color: Colors.white),
      ),
      color: wawuColors.primary,
    );
  }
}