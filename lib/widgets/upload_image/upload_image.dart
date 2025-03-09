import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  File? _image;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
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
          color: wawuColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        // padding: EdgeInsets.all(20.0),
        child:
            _image == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_rounded, size: 50),
                      SizedBox(height: 10),
                      Text('Upload Image'),
                      Text('500kb'),
                    ],
                  ),
                )
                : Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      child: Image.file(_image!, fit: BoxFit.cover),
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
                            onTap: () => setState(() => _image = null),
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
                                child: Center(
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
