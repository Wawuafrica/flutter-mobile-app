import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'dart:io' if (dart.library.html) 'dart:html'; // Conditional import for File

class UploadImage extends StatefulWidget {
  final ValueChanged<XFile?>? onImageChanged;
  final String labelText;
  final String? initialImagePath;

  const UploadImage({
    super.key,
    this.onImageChanged,
    required this.labelText,
    this.initialImagePath,
  });

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  XFile? _image;
  Uint8List? _webImageBytes;

  // IMPORTANT DEBUGGING FLAG:
  // Set this to `true` to force Web behavior, `false` to force Mobile behavior.
  // When deploying, you should typically remove this line or set it to `kIsWeb` directly.
  final bool _forceIsWeb = true; // Set to `true` for web debugging, `false` for mobile debugging

  @override
  void initState() {
    super.initState();
    // Use the forced boolean for initial image path handling
    if (widget.initialImagePath != null && !_forceIsWeb) {
      _image = XFile(widget.initialImagePath!);
    }
    // Note: For web, if you have an initial image path (e.g., a URL),
    // you'd need to fetch its bytes here to display it.
    // This example focuses on local file paths for initial mobile images.
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        // Use the forced boolean
        if (_forceIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _webImageBytes = bytes;
            });
          });
        }
      });
      if (widget.onImageChanged != null) {
        widget.onImageChanged!(_image);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _image = null;
      _webImageBytes = null;
    });
    if (widget.onImageChanged != null) {
      widget.onImageChanged!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the forced boolean for rendering logic
    final bool currentIsWeb = _forceIsWeb;

    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _image == null && _webImageBytes == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_rounded, size: 50),
                    const SizedBox(height: 10),
                    Text(widget.labelText),
                    const Text('500kb'),
                  ],
                ),
              )
            : Stack(
                children: [
                  SizedBox( // Changed Container to SizedBox for better clarity when only setting width
                    width: double.infinity,
                    child: currentIsWeb
                        ? (_webImageBytes != null
                            ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator()))
                        : (_image != null
                            ? Image.file(
                                File(_image!.path), // Added null as the first positional argument
                                fit: BoxFit.cover,
                              )
                            : const Center(child: CircularProgressIndicator())),
                  ),
                  Container(
                    width: double.infinity,
                    height: 250,
                    color: wawuColors.primary.withAlpha(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _clearImage,
                          child: ClipOval(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}