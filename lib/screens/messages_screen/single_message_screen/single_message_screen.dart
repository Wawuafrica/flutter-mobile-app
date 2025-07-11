// single_message_screen.dart
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
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/message_bubbles/message_bubbles.dart';
import 'package:wawu_mobile/widgets/voice_note_bubble/voice_note_bubble.dart';
import 'package:wawu_mobile/screens/user_profile/user_profile_screen.dart';

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
  final ScrollController _scrollController = ScrollController();

  // Store provider references to avoid accessing them after disposal
  MessageProvider? _messageProvider;
  UserProvider? _userProvider;

  // Store scaffold messenger reference safely
  ScaffoldMessengerState? _scaffoldMessenger;

  // Track previous message count for scroll optimization
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Store scaffold messenger reference safely
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    // Store provider references safely
    _messageProvider = Provider.of<MessageProvider>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!_isInitialized) {
      _initializeConversation();
      _isInitialized = true;
    }

    // Add listener using stored reference
    _messageProvider?.addListener(_onMessageProviderChange);
  }

  void _onMessageProviderChange() {
    if (!mounted) return;

    // Check if new messages were added
    final currentMessageCount = _messageProvider?.currentMessages.length ?? 0;
    if (currentMessageCount > _previousMessageCount) {
      // New message(s) received, scroll to bottom
      _scrollToBottom();
    }
    _previousMessageCount = currentMessageCount;
  }

  void _showErrorSnackbar(String message) {
    // Use the safely stored reference and check if still mounted
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSnackbar(String message, {Color? backgroundColor}) {
    // Use the safely stored reference and check if still mounted
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  Future<void> _initializeConversation() async {
    if (!mounted || _messageProvider == null || _userProvider == null) return;

    // Handle route arguments for new conversations
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final currentUserId = _userProvider?.currentUser?.uuid ?? '';

    if (args != null &&
        args.containsKey('recipientId') &&
        currentUserId.isNotEmpty &&
        _messageProvider != null) {
      final recipientId = args['recipientId'] as String;
      final initialMessage = args['initialMessage'] as String?;

      try {
        await _messageProvider!.startConversation(
          currentUserId,
          recipientId,
          initialMessage,
        );
        // Initialize message count after loading conversation
        _previousMessageCount = _messageProvider!.currentMessages.length;
        // Scroll to bottom after initialization
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Mark messages as read after conversation is initialized and messages are fetched
        if (_messageProvider != null &&
            _messageProvider!.currentConversationId.isNotEmpty) {
          _messageProvider!.markMessagesAsRead(
            _messageProvider!.currentConversationId,
            currentUserId,
          );
        }
      } catch (e) {
        _showErrorSnackbar('Error initializing conversation: $e');
      }
    } else {
      // For existing conversations, initialize message count
      _previousMessageCount = _messageProvider?.currentMessages.length ?? 0;
      // Scroll to bottom after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Mark messages as read for existing conversation
      if (_messageProvider != null &&
          _messageProvider!.currentConversationId.isNotEmpty) {
        _messageProvider!.markMessagesAsRead(
          _messageProvider!.currentConversationId,
          currentUserId,
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _messageProvider?.removeListener(_onMessageProviderChange);

    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _debounceTimer?.cancel();
    _scrollController.dispose();

    // Clear provider references
    _messageProvider = null;
    _userProvider = null;
    _scaffoldMessenger = null;

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
    if (!mounted || _messageProvider == null || _userProvider == null) return;

    if (!_isTextFieldEmpty) {
      final currentUserId = _userProvider!.currentUser?.uuid ?? '';
      final recipientId = _messageProvider!.currentRecipientId;

      if (currentUserId.isEmpty || recipientId.isEmpty) {
        _showSnackbar('User not authenticated or recipient not selected');
        return;
      }

      final message = _messageController.text.trim();
      try {
        await _messageProvider!.sendMessage(
          senderId: currentUserId,
          receiverId: recipientId,
          content: message,
        );
        if (mounted) {
          _messageController.clear();
          // Scroll to bottom after sending message
          _scrollToBottom();
        }
      } catch (e) {
        _showErrorSnackbar('Failed to send message: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    if (!mounted) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnackbar('Microphone permission denied');
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
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Recording error: $e');
      _showErrorSnackbar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!mounted || _messageProvider == null || _userProvider == null) return;

    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stop();

      if (_currentAudioPath != null) {
        final currentUserId = _userProvider!.currentUser?.uuid ?? '';
        final recipientId = _messageProvider!.currentRecipientId;

        if (currentUserId.isEmpty || recipientId.isEmpty) {
          _showSnackbar('User not authenticated or recipient not selected');
          return;
        }

        final message = await _messageProvider!.sendMessage(
          senderId: currentUserId,
          receiverId: recipientId,
          content: 'Voice message',
          mediaFilePath: _currentAudioPath!,
          mediaType: 'audio',
        );
        if (message != null && mounted) {
          _voiceMessageDurations[message.id] = _recordingDuration;
          // Scroll to bottom after sending voice message
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Stop recording error: $e');
      _showErrorSnackbar('Failed to stop recording: $e');
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

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    // Use a more reliable scroll method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // Fallback to jump if animate fails
          try {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          } catch (e2) {
            print('Scroll error: $e2');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userProvider?.currentUser?.uuid ?? '';

    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        // Show loading while initializing conversation
        // Only show CircularProgressIndicator if _currentMessages is empty
        if (messageProvider.isLoading &&
            messageProvider.currentMessages.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error if conversation failed to load and there are no messages
        if (messageProvider.hasError &&
            messageProvider.currentConversationId.isEmpty &&
            messageProvider.currentMessages.isEmpty) {
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

        // Check if we have a valid conversation, if not, show "No conversation selected"
        if (messageProvider.currentConversationId.isEmpty &&
            !messageProvider.isLoading) {
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
            title: _buildAppBarTitle(messageProvider, currentUserId),
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildMessagesList(messageProvider, currentUserId),
              ),
              _buildBottomSheet(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBarTitle(
    MessageProvider messageProvider,
    String currentUserId,
  ) {
    final conversation = messageProvider.allConversations.firstWhere(
      (conv) => conv.id == messageProvider.currentConversationId,
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    final otherParticipantId =
        conversation.participants
            .firstWhere(
              (user) => user.id != currentUserId,
              orElse: () => ChatUser(id: '', name: 'Unknown', avatar: null),
            )
            .id;

    final recipient =
        messageProvider.getCachedUserProfile(otherParticipantId) ??
        ChatUser(id: otherParticipantId, name: 'Unknown', avatar: null);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: recipient.id),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child:
                recipient.avatar != null && recipient.avatar!.isNotEmpty
                    ? Image.network(
                      recipient.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Image.asset(
                            'assets/images/other/avatar.webp',
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      'assets/images/other/avatar.webp',
                      fit: BoxFit.cover,
                    ),
          ),
          const SizedBox(width: 10),
          Text(recipient.name, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    MessageProvider messageProvider,
    String currentUserId,
  ) {
    final messages = messageProvider.currentMessages;

    // Only show "No messages yet" if not loading and messages are truly empty
    if (messages.isEmpty && !messageProvider.isLoading) {
      return const Center(child: Text('No messages yet'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLeft = message.senderId != currentUserId;
        final time = _getCurrentTime(message.timestamp);

        return ListTile(
          title:
              message.attachmentType == 'audio'
                  ? VoiceMessageBubble(
                    isLeft: isLeft,
                    source: message.attachmentUrl ?? '',
                    time: time,
                    duration: _formatDuration(
                      _voiceMessageDurations[message.id] ?? Duration.zero,
                    ),
                    status: message.status,
                    onFailedTap: () => _showResendDialog(message),
                  )
                  : MessageBubbles(
                    isLeft: isLeft,
                    message: message.content,
                    time: time,
                    status: message.status,
                    onFailedTap: () => _showResendDialog(message),
                  ),
        );
      },
    );
  }

  void _showResendDialog(message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Message Failed'),
            content: const Text('Resend or delete?'),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.pop(context);
                    if (_messageProvider != null) {
                      _messageProvider!.deleteMessage(
                        message.id,
                        // message.senderId, // senderId is not needed here
                      );
                      _messageProvider!.sendMessage(
                        senderId: message.senderId,
                        receiverId: message.receiverId,
                        content: message.content,
                        mediaFilePath: message.attachmentUrl,
                        mediaType: message.attachmentType,
                      );
                    }
                  }
                },
                child: const Text('Resend'),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.pop(context);
                    if (_messageProvider != null) {
                      _messageProvider!.deleteMessage(
                        message.id,
                        // message.senderId, // senderId is not needed here
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
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
