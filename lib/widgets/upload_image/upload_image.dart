import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _image = XFile(widget.initialImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
      if (widget.onImageChanged != null) {
        widget.onImageChanged!(_image);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _image = null;
    });
    if (widget.onImageChanged != null) {
      widget.onImageChanged!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.primary.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            _image == null
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
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: Image.file(
                        File(_image!.path),
                        key: ValueKey(
                          _image!.path,
                        ), // Ensure unique key for image
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                Text('Error loading image'),
                              ],
                            ),
                          );
                        },
                      ),
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
                            onTap: _pickImage,
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
                                    Icons.add,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
