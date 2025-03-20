import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/message_bubbles/message_bubbles.dart';
import 'package:wawu_mobile/widgets/voice_note_bubble/voice_note_bubble.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class SingleMessageScreen extends StatefulWidget {
  const SingleMessageScreen({super.key});

  @override
  State<SingleMessageScreen> createState() => _SingleMessageScreenState();
}

class _SingleMessageScreenState extends State<SingleMessageScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isRecording = false;
  String? _currentAudioPath;
  final TextEditingController _messageController = TextEditingController();
  bool _isTextFieldEmpty = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Listen to text changes
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged); // Remove listener
    _messageController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _isTextFieldEmpty = _messageController.text.trim().isEmpty;
      });
    });
  }

  void _sendMessage() {
    if (!_isTextFieldEmpty) {
      final message = _messageController.text.trim();
      // Add the message to your messages list or send it to the server
      setState(() {
        _messages.add({
          'type': 'text',
          'content': message,
          'time': _getCurrentTime(),
          'isLeft': false,
        });
      });

      // Clear the text field
      _messageController.clear();
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _currentAudioPath = path;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration += Duration(seconds: 1));
      });
    } catch (e) {
      print('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();

    if (_currentAudioPath != null) {
      _addVoiceMessage(_currentAudioPath!);
    }

    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  void _addVoiceMessage(String path) {
    final newMessage = {
      'type': 'voice',
      'duration': _formatDuration(_recordingDuration),
      'time': _getCurrentTime(),
      'isLeft': false,
      'source': path,
    };

    setState(() => _messages.add(newMessage));

    // Simulate server upload
    _uploadToServer(path).then((serverUrl) {
      // Update message with server URL
      final index = _messages.indexWhere((m) => m['localPath'] == path);
      if (index != -1) {
        setState(() => _messages[index]['source'] = serverUrl);
      }
    });
  }

  Future<String> _uploadToServer(String path) async {
    // Implement actual server upload logic here
    await Future.delayed(Duration(seconds: 2));
    return 'https://your-server.com/${path.split('/').last}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  // @override
  // void dispose() {

  //   super.dispose();
  // }

  final List<Map<String, dynamic>> _messages = [
    {
      'type': 'text',
      'content': 'Hey there! How are you doing today? 😊',
      'time': '10:31 AM',
      'isLeft': true,
    },
    {
      'type': 'text',
      'content': "I'm doing great! Working on Flutter projects 📱",
      'time': '10:35 AM',
      'isLeft': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10.0),
            width: 40,
            height: 40,
            child: Center(child: Icon(Icons.video_call)),
          ),
          Container(
            margin: EdgeInsets.only(right: 10.0),
            width: 40,
            height: 40,
            child: Center(child: Icon(Icons.call)),
          ),
        ],
        title: Row(
          spacing: 10.0,
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset('assets/images/other/avatar.png'),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: wawuColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Text('Jane Doe', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            ..._messages.map(
              (message) =>
                  message['type'] == 'text'
                      ? MessageBubbles(
                        isLeft: message['isLeft'],
                        message: message['content'],
                        time: message['time'],
                      )
                      : VoiceMessageBubble(
                        source: message['source'],
                        isLeft: message['isLeft'],
                        time: message['time'],
                        duration: message['duration'],
                      ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 10.0,
        bottom: 15.0,
        left: 10.0,
        right: 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add, color: wawuColors.purpleDarkContainer),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: wawuColors.buttonSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.transparent, width: 1),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
              child:
                  _isRecording
                      ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                            color: Color.fromARGB(255, 201, 201, 201),
                          ),
                        ),
                      )
                      : TextField(
                        controller: _messageController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: Color.fromARGB(255, 201, 201, 201),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
            ),
          ),
          !_isTextFieldEmpty
              ? IconButton(
                onPressed:
                    !_isTextFieldEmpty
                        ? _sendMessage
                        : null, // Disable if empty
                icon: Icon(Icons.send, color: wawuColors.purpleDarkContainer),
              )
              : _isRecording
              ? Container(
                margin: EdgeInsets.only(left: 10.0),
                width: 45,
                decoration: BoxDecoration(
                  color: wawuColors.purpleDarkContainer,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  highlightColor: wawuColors.purpleDarkContainer,
                  onPressed: () => _stopRecording(),
                  icon: Icon(Icons.stop, color: wawuColors.white),
                ),
              )
              : IconButton(
                icon: Icon(Icons.mic, color: wawuColors.purpleDarkContainer),
                onPressed: () => _startRecording(),
              ),
        ],
      ),
    );
  }
}
