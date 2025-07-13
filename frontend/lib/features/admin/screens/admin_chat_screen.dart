import 'package:flutter/material.dart';
import '../../user/screens/chat_conversation_screen.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';

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

class CustomAvatar extends StatelessWidget {
  final String imagePath;
  final double size;
  final bool isStory;

  const CustomAvatar({
    Key? key,
    required this.imagePath,
    this.size = 40.0,
    this.isStory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imagePath.isNotEmpty &&
        (imagePath.startsWith('http') || imagePath.startsWith('https'))) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              isStory ? Icons.person : Icons.group,
              color: Colors.grey[600],
              size: size * 0.5,
            ),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        imagePath.isNotEmpty ? imagePath : 'assets/images/profiles/user1.jpg',
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              isStory ? Icons.person : Icons.group,
              color: Colors.grey[600],
              size: size * 0.5,
            ),
          );
        },
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isStory ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isStory ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  late Future<List<Map<String, dynamic>>> _approvedUsersFuture;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _conversationsFuture = authService.fetchConversations();
    _approvedUsersFuture = authService.fetchApprovedUsers();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text('Admin Chat', style: TextStyle(color: Colors.deepPurple[700])),
          ],
        ),
        backgroundColor: Colors.deepPurple[50],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Contacts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _conversationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No conversations available.'));
              }
              final conversations = snapshot.data!
                  // Filter out self-to-self conversations (handled by Admin Notes)
                  .where((conv) =>
                      conv['user_one_id'] != currentUserId ||
                      conv['user_two_id'] != currentUserId)
                  .toList();
              return ListView.builder(
                itemCount: conversations.length + 1, // +1 for Admin Notes
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Admin Notes entry
                    return ListTile(
                      leading: const Icon(Icons.bookmark,
                          color: Colors.deepPurple, size: 40),
                      title: const Text('Admin Notes'),
                      subtitle: const Text('Your personal notes'),
                      onTap: () async {
                        try {
                          final data = await authService.fetchSavedMessages();
                          final conversationId = data['conversation_id'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatConversationScreen(
                                userName: 'Admin Notes',
                                userImage: '',
                                conversationId: conversationId,
                                receiverId: currentUserId!,
                                currentUserId: currentUserId!,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to open Admin Notes: $e')),
                          );
                        }
                      },
                    );
                  }
                  final conv = conversations[index - 1];
                  // Determine the other user (not the admin)
                  final userOne = conv['user_one'];
                  final userTwo = conv['user_two'];
                  final isUserOne = conv['user_one_id'] == currentUserId;
                  final otherUser = isUserOne ? userTwo : userOne;
                  final otherUserId =
                      isUserOne ? conv['user_two_id'] : conv['user_one_id'];
                  final userName =
                      otherUser != null && otherUser['name'] != null
                          ? otherUser['name']
                          : 'User';
                  final userImage =
                      otherUser != null && otherUser['profile_picture'] != null
                          ? otherUser['profile_picture']
                          : '';
                  final lastMessage = conv['last_message'] != null
                      ? conv['last_message']['message'] ?? 'No messages yet'
                      : 'No messages yet';
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
                            currentUserId: currentUserId!,
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
            future: Future.wait([_approvedUsersFuture, _conversationsFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data![0].isEmpty) {
                return const Center(
                    child: Text('No approved users available.'));
              }
              final users = (snapshot.data![0] as List)
                  // Filter out the admin
                  .where((user) => user['id'] != currentUserId)
                  .toList();
              final conversations = (snapshot.data![1] as List);
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userName = user['name'] ?? 'User';
                  final userImage = user['profile_picture'] ?? '';
                  final userId = user['id'];
                  // Find existing conversation with this user
                  final existingConv = (conversations.firstWhere(
                    (conv) =>
                        (conv['user_one_id'] == currentUserId &&
                            conv['user_two_id'] == userId) ||
                        (conv['user_two_id'] == currentUserId &&
                            conv['user_one_id'] == userId),
                    orElse: () => <String, dynamic>{},
                  ) as Map<String, dynamic>);
                  final conversationId = (existingConv.isNotEmpty &&
                          existingConv.containsKey('id'))
                      ? existingConv['id']
                      : 0;
                  final lastMessage = (existingConv.isNotEmpty &&
                          existingConv['last_message'] != null)
                      ? (existingConv['last_message']['message'] ??
                          'No messages yet')
                      : (user['email'] ?? 'No messages yet');
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
                            currentUserId: currentUserId!,
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
    );
  }
}
