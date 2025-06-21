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
  final String? status;
  final VoidCallback? onFailedTap;

  const VoiceMessageBubble({
    super.key,
    required this.isLeft,
    required this.source,
    required this.time,
    required this.duration,
    this.status,
    this.onFailedTap,
  });

  @override
  _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  static AudioPlayer? _currentlyPlayingPlayer;

  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final GlobalKey _progressKey = GlobalKey();

  // Store scaffold messenger reference safely
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer(widget.source); // Initialize with the provided source
    _checkExistingFile(); // Check if file already exists
    _setupAudioListeners(); // Setup audio listeners
    if (_isNetwork && !_isDownloaded && !_isDownloading) {
      _downloadFile(); // Start download immediately if it's a network source
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely store ScaffoldMessenger reference
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  bool get _isNetwork => widget.source.startsWith('http');

  Future<void> _initAudioPlayer(String source) async {
    try {
      // Set source as URL for remote audio
      await _audioPlayer.setUrl(source);
      // Listen for duration changes to update UI
      _audioPlayer.durationStream.listen((Duration? d) {
        if (d != null && mounted) {
          setState(() {
            _duration = d;
          });
        }
      });
      // Listen for position changes to update slider
      _audioPlayer.positionStream.listen((Duration p) {
        if (mounted) {
          setState(() {
            _position = p;
          });
        }
      });
      // Listen for player state changes
      _audioPlayer.playerStateStream.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    // Use the safely stored reference and check if still mounted
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(SnackBar(content: Text(message)));
    }
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
      if (_audioPlayer.processingState != ProcessingState.completed &&
          mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration ?? Duration.zero);
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed && mounted) {
        _resetToStart();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  Future<void> _resetToStart() async {
    if (!mounted) return;

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
    if (_isDownloading || _isDownloaded || !mounted) return;

    if (mounted) {
      setState(() => _isDownloading = true);
    }

    try {
      final client = Dio();
      final path = await _getSanitizedPath();
      final dir = path.substring(0, path.lastIndexOf('/'));
      await Directory(dir).create(recursive: true);

      await client.download(
        widget.source,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() => _isDownloaded = true);
        await _initAudioPlayer(widget.source);
      }
    } catch (e) {
      // This is the critical fix - safe error handling
      if (mounted) {
        setState(() => _isDownloading = false);
        _showErrorSnackbar('Failed to download audio: $e');
      }
    }
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    // Clean up audio player before disposing
    _audioPlayer.dispose();
    _scaffoldMessenger = null;
    super.dispose();
  }

  void _handleSeek(Offset localPosition) {
    if (!mounted) return;

    final box = _progressKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final width = box.size.width;
    final percent = (localPosition.dx / width).clamp(0.0, 1.0);
    final newPosition = _duration * percent;

    _audioPlayer.seek(newPosition);
    if (mounted) {
      setState(() => _position = newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildDownloadSection(iconColor, widget.isLeft),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              widget.isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (widget.status == 'pending')
              Icon(Icons.access_time, size: 12, color: Colors.grey),
            if (widget.status == 'sent')
              Icon(Icons.done, size: 12, color: Colors.green),
            if (widget.status == 'failed')
              GestureDetector(
                onTap: widget.onFailedTap,
                child: Icon(Icons.error, size: 12, color: Colors.red),
              ),
            if (widget.status != null) SizedBox(width: 5),
            Text(
              widget.time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
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
                onPressed: _togglePlayPause,
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
                  onPressed: _togglePlayPause,
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

  Future<void> _togglePlayPause() async {
    if (!mounted) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      _currentlyPlayingPlayer = null;
    } else {
      // Stop any currently playing voice note
      if (_currentlyPlayingPlayer != null &&
          _currentlyPlayingPlayer != _audioPlayer) {
        await _currentlyPlayingPlayer!.stop();
      }
      _currentlyPlayingPlayer = _audioPlayer;
      await _audioPlayer.play();
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    }
  }

  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      _initAudioPlayer(widget.source); // Reinitialize if source changes
    }
  }
}
