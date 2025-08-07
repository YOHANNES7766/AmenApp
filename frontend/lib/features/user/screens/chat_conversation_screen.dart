import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';

class Message {
  final int id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    return Message(
      id: json['id'],
      text: json['message'],
      isMe: json['sender_id'] == currentUserId,
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final String userName;
  final String userImage;
  final int conversationId;
  final int receiverId;
  final int currentUserId;

  const ChatConversationScreen({
    Key? key,
    required this.userName,
    required this.userImage,
    required this.conversationId,
    required this.receiverId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _error;
  late PusherChannelsFlutter _pusher;
  late int _currentUserId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUserId;
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    _authToken = authService.accessToken;
    await _fetchMessages();
    await _initPusher();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMessages() async {
    // If conversationId is 0, it's a new conversation, so no messages to fetch
    if (widget.conversationId == 0) {
      setState(() {
        _messages.clear();
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse(
          '$backendBaseUrl/api/chat/messages/${widget.conversationId}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(
              data.map((json) => Message.fromJson(json, _currentUserId)));
        });
        _scrollToBottom();
      } else {
        setState(() => _error = 'Failed to load messages');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load messages: $e');
    }
  }

  Future<void> _initPusher() async {
    _pusher = PusherChannelsFlutter();
    final authService = Provider.of<AuthService>(context, listen: false);
    await _pusher.init(
      apiKey: 'YOUR_PUSHER_KEY', // <-- Replace with your Pusher key
      cluster: 'YOUR_PUSHER_CLUSTER', // <-- Replace with your Pusher cluster
      authEndpoint: '$backendBaseUrl/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        return {
          'headers': {
            'Authorization': 'Bearer ${authService.accessToken}',
            'Accept': 'application/json',
          }
        };
      },
      onEvent: (event) {
        if (event.eventName == 'App\\Events\\MessageSent') {
          final data = jsonDecode(event.data);
          final msg = Message.fromJson(data['message'], _currentUserId);
          setState(() {
            _messages.add(msg);
          });
          _scrollToBottom();
        }
      },
    );
    await _pusher.subscribe(
        channelName: 'private-conversation.${widget.conversationId}');
    await _pusher.connect();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pusher.disconnect();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse('$backendBaseUrl/api/chat/send');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${authService.accessToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiver_id': widget.receiverId,
          'message': messageText,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Create a local message object
        final newMessage = Message(
          id: responseData['id'],
          text: messageText,
          isMe: true,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(newMessage);
          _isLoading = false;
          _error = null;
        });

        _scrollToBottom();
      } else {
        setState(() {
          _error = 'Failed to send message: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to send message: $e';
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/images/profiles/default_profile.png';
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    if (imagePath.startsWith('/storage/')) {
      return backendBaseUrl + imagePath;
    }
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: widget.userName == 'Saved Messages'
            ? const Row(
                children: [
                  Icon(Icons.bookmark, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Saved Messages',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.userImage.isNotEmpty
                        ? (widget.userImage.startsWith('http') ||
                                widget.userImage.startsWith('/storage/')
                            ? NetworkImage(getFullImageUrl(widget.userImage))
                            : AssetImage(getFullImageUrl(widget.userImage))
                                as ImageProvider)
                        : const AssetImage(
                            'assets/images/profiles/default_profile.png'),
                    child: widget.userImage.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        actions: widget.userName == 'Saved Messages'
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.video_call),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
      ),
      body: Column(
        children: [
          // Error message at the top if there's an error
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red[100],
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red[700], size: 16),
                    onPressed: () => setState(() => _error = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showTimestamp = index == _messages.length - 1 ||
                              _messages[index + 1].isMe != message.isMe;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: message.isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!message.isMe && showTimestamp)
                                  const Text('Avatar'),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.isMe
                                        ? Theme.of(context)
                                            .primaryColor
                                            .withAlpha(26)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.text,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (showTimestamp)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          // Message input - always visible
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}