import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> conversations = [];
  bool isLoading = false;
  String? error;

  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final url = Uri.parse('$backendBaseUrl/api/chat/conversations');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${_authService.accessToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          conversations = data;
        });
      } else {
        throw 'Failed to load conversations.';
      }
    } catch (e) {
      setState(() => error = 'Error loading chats: $e');
    }

    setState(() => isLoading = false);
  }

  void _openChat(Map<String, dynamic> convo) {
    final receiverId = convo['receiver_id'] is int
        ? convo['receiver_id']
        : int.tryParse(convo['receiver_id'].toString()) ?? 0;

    final conversationId = convo['id'] is int
        ? convo['id']
        : int.tryParse(convo['id'].toString()) ?? 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          userName: convo['receiver_name'] ?? 'Unknown',
          userImage: convo['receiver_image'] ?? '',
          conversationId: conversationId,
          receiverId: receiverId,
          currentUserId: _authService.currentUserId ?? 0,
        ),
      ),
    );
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'assets/images/profiles/default_profile.png';
    }
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage/')) return backendBaseUrl + path;
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchConversations,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : conversations.isEmpty
                  ? const Center(child: Text('No conversations found.'))
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final convo = conversations[index];
                        final name = convo['receiver_name'] ?? 'Unknown';
                        final image = getFullImageUrl(convo['receiver_image']);
                        final lastMsg = convo['last_message'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: image.contains('http')
                                ? NetworkImage(image)
                                : AssetImage(image) as ImageProvider,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _openChat(convo),
                        );
                      },
                    ),
    );
  }
}
