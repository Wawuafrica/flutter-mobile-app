import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class UploadVideo extends StatefulWidget {
  final String labelText;
  final ValueChanged<XFile?> onVideoChanged;
  final String? initialVideoPath;

  const UploadVideo({
    super.key,
    required this.labelText,
    required this.onVideoChanged,
    this.initialVideoPath,
  });

  @override
  State<UploadVideo> createState() => _UploadVideoState();
}

class _UploadVideoState extends State<UploadVideo> {
  XFile? _video;

  // IMPORTANT DEBUGGING FLAG:
  // Set this to `true` to force Web behavior, `false` to force Mobile behavior.
  // When deploying, you should typically remove this line or set it to `kIsWeb` directly.
  final bool _forceIsWeb = true; // Set to `true` for web debugging, `false` for mobile debugging

  @override
  void initState() {
    super.initState();
    // Use the forced boolean for initial video path handling
    if (widget.initialVideoPath != null && !_forceIsWeb) {
      _video = XFile(widget.initialVideoPath!);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null) {
        setState(() {
          _video = video;
        });
        widget.onVideoChanged(video);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      widget.onVideoChanged(null);
    }
  }

  void _clearVideo() {
    setState(() {
      _video = null;
    });
    widget.onVideoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    // Use the forced boolean for rendering logic

    return InkWell(
      onTap: _pickVideo,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.primary.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _video == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_library_rounded, size: 50),
                    const SizedBox(height: 10),
                    Text(widget.labelText),
                    const Text('Max 50MB'),
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
                          Icons.video_file_rounded,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _video!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Video Selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                          onTap: _pickVideo,
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
                          onTap: _clearVideo,
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