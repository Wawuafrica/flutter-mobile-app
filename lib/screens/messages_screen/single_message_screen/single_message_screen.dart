import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/user_profile/user_profile.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/message_bubbles/message_bubbles.dart';
import 'package:wawu_mobile/widgets/voice_note_bubble/voice_note_bubble.dart';

class SingleMessageScreen extends StatefulWidget {
  const SingleMessageScreen({super.key});

  @override
  State<SingleMessageScreen> createState() => _SingleMessageScreenState();
}

class _SingleMessageScreenState extends State<SingleMessageScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _messageController = TextEditingController();
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isRecording = false;
  String? _currentAudioPath;
  bool _isTextFieldEmpty = true;
  Timer? _debounceTimer;
  final Map<String, Duration> _voiceMessageDurations = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeConversation();
      _isInitialized = true;
    }
  }

  Future<void> _initializeConversation() async {
    // Handle route arguments for new conversations
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).currentUser?.uuid ??
        '';

    if (args != null &&
        args.containsKey('recipientId') &&
        currentUserId.isNotEmpty) {
      final recipientId = args['recipientId'] as String;
      final initialMessage = args['initialMessage'] as String?;

      try {
        await messageProvider.startConversation(
          currentUserId,
          recipientId,
          initialMessage,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error initializing conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isTextFieldEmpty = _messageController.text.trim().isEmpty;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (!_isTextFieldEmpty) {
      final currentUserId =
          Provider.of<UserProvider>(context, listen: false).currentUser?.uuid ??
          '';
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );
      final recipientId = messageProvider.currentRecipientId;

      if (currentUserId.isEmpty || recipientId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated or recipient not selected'),
            ),
          );
        }
        return;
      }

      final message = _messageController.text.trim();
      try {
        await messageProvider.sendMessage(
          senderId: currentUserId,
          receiverId: recipientId,
          content: message,
        );
        _messageController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _currentAudioPath = path;
          _recordingDuration = Duration.zero;
        });
      }

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (e) {
      print('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stop();

      if (_currentAudioPath != null) {
        final currentUserId =
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).currentUser?.uuid ??
            '';
        final messageProvider = Provider.of<MessageProvider>(
          context,
          listen: false,
        );
        final recipientId = messageProvider.currentRecipientId;

        if (currentUserId.isEmpty || recipientId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'User not authenticated or recipient not selected',
                ),
              ),
            );
          }
          return;
        }

        final message = await messageProvider.sendMessage(
          senderId: currentUserId,
          receiverId: recipientId,
          content: 'Voice message',
          mediaFilePath: _currentAudioPath!,
          mediaType: 'audio',
        );
        if (message != null) {
          _voiceMessageDurations[message.id] = _recordingDuration;
        }
      }
    } catch (e) {
      print('Stop recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _currentAudioPath = null;
        });
      }
    }
  }

  String _getCurrentTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<UserProvider>(context).currentUser?.uuid ?? '';
    final messageProvider = Provider.of<MessageProvider>(context);

    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    // Show loading while initializing conversation
    if (messageProvider.isLoading &&
        messageProvider.currentConversationId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show error if conversation failed to load
    if (messageProvider.hasError &&
        messageProvider.currentConversationId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${messageProvider.errorMessage}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if we have a valid conversation
    if (messageProvider.currentConversationId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No conversation selected'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            width: 40,
            height: 40,
            child: const Center(child: Icon(Icons.video_call)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            width: 40,
            height: 40,
            child: const Center(child: Icon(Icons.call)),
          ),
        ],
        title: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            final conversation = messageProvider.allConversations.firstWhere(
              (conv) => conv.id == messageProvider.currentConversationId,
              orElse:
                  () => Conversation(id: '', participants: [], messages: []),
            );
            final otherParticipant = conversation.participants.firstWhere(
              (user) => user.id != currentUserId,
              orElse: () => ChatUser(id: '', name: 'Unknown', avatar: null),
            );

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => SellerProfileScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child:
                            otherParticipant.avatar != null
                                ? Image.network(
                                  otherParticipant.avatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                            'assets/images/other/avatar.webp',
                                            fit: BoxFit.cover,
                                          ),
                                )
                                : Image.asset(
                                  'assets/images/other/avatar.webp',
                                  fit: BoxFit.cover,
                                ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            // color: wawuColors.primary,
                            shape: BoxShape.circle,
                            // border: Border.all(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  otherParticipant.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        margin: const EdgeInsets.only(bottom: 60.0),
        child: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            final messages = messageProvider.currentMessages;

            if (messageProvider.isLoading && messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                  reverse: true, // Show newest messages at bottom
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const SizedBox(height: 20);
                    }
                    // Reverse the index to show messages in correct order
                    final message = messages[messages.length - 1 - index];
                    final isLeft = message.senderId != currentUserId;
                    final time = _getCurrentTime(message.timestamp);

                    return message.attachmentType == 'audio'
                        ? VoiceMessageBubble(
                          isLeft: isLeft,
                          source:
                              message.attachmentUrl ?? _currentAudioPath ?? '',
                          time: time,
                          duration:
                              _voiceMessageDurations[message.id] != null
                                  ? _formatDuration(
                                    _voiceMessageDurations[message.id]!,
                                  )
                                  : '0:00',
                        )
                        : MessageBubbles(
                          isLeft: isLeft,
                          message: message.content,
                          time: time,
                        );
                  },
                );
          },
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(
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
              padding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
              child:
                  _isRecording
                      ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 201, 201, 201),
                          ),
                        ),
                      )
                      : TextField(
                        controller: _messageController,
                        maxLines: 1,
                        decoration: const InputDecoration(
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
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: wawuColors.purpleDarkContainer),
              )
              : _isRecording
              ? Container(
                margin: const EdgeInsets.only(left: 10.0),
                width: 45,
                decoration: BoxDecoration(
                  color: wawuColors.purpleDarkContainer,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  highlightColor: wawuColors.purpleDarkContainer,
                  onPressed: _stopRecording,
                  icon: Icon(Icons.stop, color: wawuColors.white),
                ),
              )
              : IconButton(
                icon: Icon(Icons.mic, color: wawuColors.purpleDarkContainer),
                onPressed: _startRecording,
              ),
        ],
      ),
    );
  }
}
