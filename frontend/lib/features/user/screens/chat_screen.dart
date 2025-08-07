// ✅ Updated ChatScreen (with preloaded futures, type safety, and context safety)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';

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

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  late Future<List<Map<String, dynamic>>> _approvedUsersFuture;
  late int _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.currentUserId!;
    _conversationsFuture = authService.fetchConversations();
    _approvedUsersFuture = authService.fetchApprovedUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Chats'), Tab(text: 'Contacts')],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Chats Tab
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No conversations available.'));
                }
                final conversations = snapshot.data!;
                return ListView.builder(
                  itemCount: conversations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.bookmark, color: Colors.blue, size: 40),
                        title: const Text('Saved Messages'),
                        subtitle: const Text('Your personal notes'),
                        onTap: () async {
                          try {
                            final data = await authService.fetchSavedMessages();
                            final conversationId = data['conversation_id'] ?? 0;
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatConversationScreen(
                                  userName: 'Saved Messages',
                                  userImage: '',
                                  conversationId: conversationId,
                                  receiverId: _currentUserId,
                                  currentUserId: _currentUserId,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to open Saved Messages: $e')),
                            );
                          }
                        },
                      );
                    }

                    final conv = conversations[index - 1];
                    final userOne = conv['user_one'];
                    final userTwo = conv['user_two'];
                    final isUserOne = conv['user_one_id'] == _currentUserId;
                    final otherUser = isUserOne ? userTwo : userOne;
                    final otherUserId = isUserOne
                        ? conv['user_two_id']
                        : conv['user_one_id'];
                    final userName = otherUser?['name'] ?? 'User';
                    final userImage = otherUser?['profile_picture'] ?? '';
                    final lastMessage = conv['last_message']?['message'] ?? 'No messages yet';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userImage.isNotEmpty
                            ? (userImage.startsWith('http') ||
                                    userImage.startsWith('/storage/')
                                ? NetworkImage(getFullImageUrl(userImage))
                                : AssetImage(getFullImageUrl(userImage))
                                    as ImageProvider)
                            : const AssetImage(
                                'assets/images/profiles/default_profile.png'),
                        child:
                            userImage.isEmpty ? const Icon(Icons.person) : null,
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
                              conversationId: conv['id'],
                              receiverId: otherUserId,
                              currentUserId: _currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            // Contacts Tab
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
                } else if (!snapshot.hasData || snapshot.data![0].isEmpty) {
                  return const Center(child: Text('No approved users available.'));
                }
                final users = (snapshot.data![0] as List)
                    .where((user) => user['id'] != _currentUserId)
                    .toList();
                final conversations = (snapshot.data![1] as List);

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userName = user['name'] ?? 'User';
                    final userImage = user['profile_picture'] ?? '';
                    final userId = user['id'];

                    final existingConv = conversations.firstWhere(
                      (conv) =>
                          (conv['user_one_id'] == _currentUserId &&
                              conv['user_two_id'] == userId) ||
                          (conv['user_two_id'] == _currentUserId &&
                              conv['user_one_id'] == userId),
                      orElse: () => <String, dynamic>{},
                    );

                    final conversationId =
                        existingConv['id'] ?? 0;
                    final lastMessage = existingConv['last_message']?['message'] ??
                        user['email'] ?? 'No messages yet';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userImage.isNotEmpty
                            ? (userImage.startsWith('http') ||
                                    userImage.startsWith('/storage/')
                                ? NetworkImage(getFullImageUrl(userImage))
                                : AssetImage(getFullImageUrl(userImage))
                                    as ImageProvider)
                            : const AssetImage(
                                'assets/images/profiles/default_profile.png'),
                        child:
                            userImage.isEmpty ? const Icon(Icons.person) : null,
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
                              currentUserId: _currentUserId,
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
    );
  }
}
