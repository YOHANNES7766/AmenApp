import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';
import 'chats_tab.dart';

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

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  late Future<List<Map<String, dynamic>>> _approvedUsersFuture;
  late PusherChannelsFlutter pusher;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    currentUserId = authService.currentUserId;

    _conversationsFuture = authService.fetchConversations();
    _approvedUsersFuture = authService.fetchApprovedUsers();

    _tabController = TabController(length: 2, vsync: this);
    _initPusher();
  }

  void _refreshConversations() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _conversationsFuture = authService.fetchConversations();
    });
  }

  void _initPusher() async {
    pusher = PusherChannelsFlutter();

    await pusher.init(
      apiKey: "4c83807283760dab1b1d",
      cluster: "mt1",
      onEvent: (event) {
        if (event.eventName == 'App\\Events\\MessageSent') {
          final data = jsonDecode(event.data);
          final message = data['message'];
          final senderId = message['sender_id'];
          final receiverId = message['receiver_id'];

          if (senderId == currentUserId || receiverId == currentUserId) {
            _refreshConversations();
          }
        }
      },
    );

    await pusher.subscribe(channelName: 'chat');
    await pusher.connect();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final int nonNullUserId = currentUserId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Contacts'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ChatsTab(
                    conversationsFuture: _conversationsFuture,
                    currentUserId: nonNullUserId,
                    authService: authService,
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      _approvedUsersFuture,
                      _conversationsFuture,
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final approvedUsers = snapshot.data![0] as List;
                      final conversations = snapshot.data![1] as List;

                      final users = approvedUsers.where((user) => user['id'] != nonNullUserId).toList();

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userName = user['name'] ?? 'User';
                          final userImage = user['profile_picture'] ?? '';
                          final userId = user['id'];

                          final existingConv = conversations.firstWhere(
                            (conv) =>
                                (conv['user_one_id'] == nonNullUserId && conv['user_two_id'] == userId) ||
                                (conv['user_two_id'] == nonNullUserId && conv['user_one_id'] == userId),
                            orElse: () => {},
                          ) as Map<String, dynamic>;

                          final conversationId = existingConv.isNotEmpty && existingConv.containsKey('id')
                              ? existingConv['id']
                              : 0;

                          final lastMessage = (existingConv.isNotEmpty &&
                                  existingConv['last_message'] != null)
                              ? (existingConv['last_message']['message'] ?? 'No messages yet')
                              : 'Start a conversation';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userImage.isNotEmpty
                                  ? (userImage.startsWith('http') || userImage.startsWith('/storage/')
                                      ? NetworkImage(getFullImageUrl(userImage))
                                      : AssetImage(getFullImageUrl(userImage)) as ImageProvider)
                                  : const AssetImage('assets/images/profiles/default_profile.png'),
                              child: userImage.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userName),
                            subtitle: Text(lastMessage),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatConversationScreen(
                                    userName: userName,
                                    userImage: userImage,
                                    conversationId: conversationId,
                                    receiverId: userId,
                                    currentUserId: nonNullUserId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
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
