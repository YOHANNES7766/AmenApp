// chat_conversation_screen.dart
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
  bool _isSending = false;
  String? _error;
  late PusherChannelsFlutter _pusher;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchMessages(),
        _initPusher(),
      ]);
    } catch (e) {
      setState(() => _error = 'Initialization error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMessages() async {
    if (widget.conversationId == 0) return;

    try {
      final url = Uri.parse('$backendBaseUrl/api/chat/messages/${widget.conversationId}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${_authService.accessToken}',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(data.map((json) => Message.fromJson(json, widget.currentUserId)));
        });
        _scrollToBottom();
      } else {
        setState(() => _error = 'Failed to load messages');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  Future<void> _initPusher() async {
    _pusher = PusherChannelsFlutter();
    await _pusher.init(
      apiKey: 'YOUR_PUSHER_KEY',
      cluster: 'YOUR_PUSHER_CLUSTER',
      authEndpoint: '$backendBaseUrl/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        return {
          'headers': {
            'Authorization': 'Bearer ${_authService.accessToken}',
            'Accept': 'application/json',
          }
        };
      },
      onEvent: (event) {
        if (event.eventName == 'App\\Events\\MessageSent') {
          final data = jsonDecode(event.data);
          final msg = Message.fromJson(data['message'], widget.currentUserId);
          setState(() {
            _messages.add(msg);
          });
          _scrollToBottom();
        }
      },
    );
    await _pusher.subscribe(channelName: 'private-conversation.${widget.conversationId}');
    await _pusher.connect();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/chat/send'),
        headers: {
          'Authorization': 'Bearer ${_authService.accessToken}',
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
        final newMessage = Message(
          id: responseData['id'],
          text: messageText,
          isMe: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(newMessage);
          _error = null;
        });
        _scrollToBottom();
      } else {
        setState(() => _error = 'Failed to send message.');
      }
    } catch (e) {
      setState(() => _error = 'Error sending message: $e');
    }

    setState(() => _isSending = false);
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pusher.disconnect();
    super.dispose();
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/images/profiles/default_profile.png';
    }
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/storage/')) return backendBaseUrl + imagePath;
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userImage.isNotEmpty
                  ? NetworkImage(getFullImageUrl(widget.userImage))
                  : const AssetImage('assets/images/profiles/default_profile.png') as ImageProvider,
              radius: 18,
              child: widget.userImage.isEmpty ? const Icon(Icons.person, size: 18) : null,
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _error = null),
                  )
                ],
              ),
            ),
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg.text),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
