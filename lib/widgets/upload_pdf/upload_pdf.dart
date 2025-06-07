import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class UploadPdf extends StatefulWidget {
  final String labelText;
  final ValueChanged<XFile?> onPdfChanged;
  final String? initialPdfPath;

  const UploadPdf({
    super.key,
    required this.labelText,
    required this.onPdfChanged,
    this.initialPdfPath,
  });

  @override
  State<UploadPdf> createState() => _UploadPdfState();
}

class _UploadPdfState extends State<UploadPdf> {
  XFile? _pdf;
  String? _fileName;

  // IMPORTANT DEBUGGING FLAG:
  // Set this to `true` to force Web behavior, `false` to force Mobile behavior.
  // When deploying, you should typically remove this line or set it to `kIsWeb` directly.
  final bool _forceIsWeb =
      true; // Set to `true` for web debugging, `false` for mobile debugging

  @override
  void initState() {
    super.initState();
    // Use the forced boolean for initial PDF path handling
    if (widget.initialPdfPath != null && !_forceIsWeb) {
      _pdf = XFile(widget.initialPdfPath!);
      _fileName = widget.initialPdfPath!.split('/').last;
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final xFile = XFile(file.path!);

        setState(() {
          _pdf = xFile;
          _fileName = file.name;
        });

        widget.onPdfChanged(xFile);
      } else {
        widget.onPdfChanged(null);
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      widget.onPdfChanged(null);
    }
  }

  void _clearPdf() {
    setState(() {
      _pdf = null;
      _fileName = null;
    });
    widget.onPdfChanged(null);
  }

  // String _formatFileSize(int bytes) {
  //   if (bytes <= 0) return "0 B";
  //   const suffixes = ["B", "KB", "MB", "GB"];
  //   int i = (bytes.bitLength - 1) ~/ 10;
  //   return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  // }

  @override
  Widget build(BuildContext context) {
    // Use the forced boolean for rendering logic
    // final bool currentIsWeb = _forceIsWeb;

    return InkWell(
      onTap: _pickPdf,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            _pdf == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, size: 50),
                      const SizedBox(height: 10),
                      Text(widget.labelText),
                      const Text('Max 10MB'),
                    ],
                  ),
                )
                : Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: wawuColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 80,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              _fileName ?? 'PDF Document',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'PDF Selected',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
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
                            onTap: _pickPdf,
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
                            onTap: _clearPdf,
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
