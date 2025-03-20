import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VoiceMessageBubble extends StatefulWidget {
  final bool isLeft;
  final String source;
  final String time;
  final String duration;

  const VoiceMessageBubble({
    super.key,
    required this.isLeft,
    required this.source,
    required this.time,
    required this.duration,
  });

  @override
  _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final GlobalKey _progressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _checkExistingFile();
    _setupAudioListeners();
  }

  bool get _isNetwork => widget.source.startsWith('http');

  // Proper audio initialization flow
  Future<void> _initAudio() async {
    try {
      if (_isNetwork) {
        if (_isDownloaded) {
          final path = await _getSanitizedPath();
          await _audioPlayer.setAudioSource(AudioSource.file((path)));
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
        }
      } else {
        final file = widget.source;
        await _audioPlayer.setAudioSource(AudioSource.file(file));
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });
      }
      setState(() => _isDownloaded = true);
    } catch (e) {
      print("Audio initialization error: $e");
      _showErrorSnackbar('Failed to load audio: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Improved file existence check
  Future<void> _checkExistingFile() async {
    if (!_isNetwork) return;

    try {
      final path = await _getSanitizedPath();
      final exists = await File(path).exists();
      if (mounted) {
        setState(() => _isDownloaded = exists);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloaded = false);
      }
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (_audioPlayer.processingState != ProcessingState.completed) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      setState(() => _duration = duration ?? Duration.zero);
    });

    _audioPlayer.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        _resetToStart();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _resetToStart() async {
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.pause();
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
      });
    }
  }

  Future<String> _getSanitizedPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final uri = Uri.parse(widget.source);
    final filename = uri.pathSegments.last.split('?').first;
    return '${dir.path}/$filename';
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final Dio dioInstance = Dio();
      final savePath = await _getSanitizedPath();
      print(savePath);

      await dioInstance.download(
        widget.source,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() => _isDownloaded = true);
      }
      await _initAudio();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleSeek(Offset localPosition) {
    final box = _progressKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final width = box.size.width;
    final percent = (localPosition.dx / width).clamp(0.0, 1.0);
    final newPosition = _duration * percent;

    _audioPlayer.seek(newPosition);
    setState(() => _position = newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _duration.inMilliseconds > 0
            ? _position.inMilliseconds / _duration.inMilliseconds
            : 0.0;
    final iconColor = widget.isLeft ? wawuColors.primary : wawuColors.white;

    return Column(
      crossAxisAlignment:
          widget.isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            minWidth: 150,
          ),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color:
                widget.isLeft
                    ? wawuColors.primary.withAlpha(30)
                    : wawuColors.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft:
                  !widget.isLeft ? const Radius.circular(15) : Radius.zero,
              bottomRight:
                  widget.isLeft ? const Radius.circular(15) : Radius.zero,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDownloadSection(iconColor, true),
                  const SizedBox(width: 10),
                  _buildProgressBar(),
                  const SizedBox(width: 10),
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(color: iconColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          widget.time,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDownloadSection(Color iconColor, bool isLocal) {
    return isLocal
        ? SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: iconColor,
                ),
                onPressed: _handlePlayPause,
              ),
            ],
          ),
        )
        : SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!_isDownloaded)
                CircularPercentIndicator(
                  radius: 20,
                  lineWidth: 2,
                  percent: _downloadProgress,
                  progressColor: iconColor,
                  backgroundColor: iconColor.withOpacity(0.2),
                ),

              if (!_isDownloaded)
                IconButton(
                  icon:
                      _isDownloaded
                          ? Icon(Icons.check, color: iconColor)
                          : FaIcon(
                            FontAwesomeIcons.arrowDown,
                            size: 10,
                            color: iconColor,
                          ),
                  onPressed: _isDownloading ? null : _downloadFile,
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                ),
              if (_isDownloaded)
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: iconColor,
                  ),
                  onPressed: _handlePlayPause,
                ),
            ],
          ),
        );
  }

  Widget _buildProgressBar() {
    final progress =
        _duration.inMilliseconds > 0
            ? _position.inMilliseconds / _duration.inMilliseconds
            : 0.0;

    return Expanded(
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => _handleSeek(d.localPosition),
        onTapDown: (d) => _handleSeek(d.localPosition),
        child: Container(
          key: _progressKey,
          // minWidh: 100,
          height: 24,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                width: 100,
                height: 2,
                decoration: BoxDecoration(
                  color: (widget.isLeft ? wawuColors.primary : wawuColors.white)
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 100 * progress,
                height: 2,
                decoration: BoxDecoration(
                  color: widget.isLeft ? wawuColors.primary : wawuColors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration) await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    }
  }
}
