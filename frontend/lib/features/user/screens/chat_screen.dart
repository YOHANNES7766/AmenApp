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
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _approvedUsers = [];
  bool _isLoading = true;
  late int _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = authService.currentUserId!;
      final conversations = await authService.fetchConversations();
      final approved = await authService.fetchApprovedUsers();

      setState(() {
        _conversations = conversations
            .where((conv) =>
                conv['user_one_id'] != _currentUserId &&
                conv['user_two_id'] != _currentUserId)
            .toList();
        _approvedUsers =
            approved.where((u) => u['id'] != _currentUserId).toList();
        _isLoading = false;
      });
    });
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
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Contacts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Chats Tab
                ListView.builder(
                  itemCount: _conversations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.bookmark,
                            color: Colors.blue, size: 40),
                        title: const Text('Saved Messages'),
                        subtitle: const Text('Your personal notes'),
                        onTap: () async {
                          try {
                            final data =
                                await authService.fetchSavedMessages();
                            final conversationId = data['conversation_id'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversationScreen(
                                  userName: 'Saved Messages',
                                  userImage: '',
                                  conversationId: conversationId,
                                  receiverId: _currentUserId,
                                  currentUserId: _currentUserId,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Failed to open Saved Messages: $e')));
                          }
                        },
                      );
                    }

                    final conv = _conversations[index - 1];
                    final isUserOne =
                        conv['user_one_id'] == _currentUserId;
                    final otherUser =
                        isUserOne ? conv['user_two'] : conv['user_one'];
                    final otherUserId = isUserOne
                        ? conv['user_two_id']
                        : conv['user_one_id'];

                    if (otherUser == null) return const SizedBox();

                    final userName = otherUser['name'] ?? 'User';
                    final userImage = otherUser['profile_picture'] ?? '';
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
                        child: userImage.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(userName),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationScreen(
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
                ),

                // Contacts Tab
                ListView.builder(
                  itemCount: _approvedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _approvedUsers[index];
                    final userName = user['name'] ?? 'User';
                    final userImage = user['profile_picture'] ?? '';
                    final userId = user['id'];

                    final existingConv = _conversations.firstWhere(
                      (conv) =>
                          (conv['user_one_id'] == _currentUserId &&
                              conv['user_two_id'] == userId) ||
                          (conv['user_two_id'] == _currentUserId &&
                              conv['user_one_id'] == userId),
                      orElse: () => {},
                    );

                    final conversationId =
                        existingConv.isNotEmpty ? existingConv['id'] : 0;
                    final lastMessage = existingConv['last_message'] != null
                        ? existingConv['last_message']['message'] ??
                            'No messages yet'
                        : user['email'] ?? 'No messages yet';

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
                        child: userImage.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(userName),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationScreen(
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
                ),
              ],
            ),
    );
  }
}
