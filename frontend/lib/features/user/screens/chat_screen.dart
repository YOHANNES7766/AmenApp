// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUserId;
    final convs = await authService.fetchConversations();
    final users = await authService.fetchApprovedUsers();

    // Filter out self-conversations
    final filteredConvs = convs.where((conv) {
      return conv['user_one_id'] != currentUserId &&
             conv['user_two_id'] != currentUserId;
    }).toList();

    setState(() {
      _conversations = filteredConvs;
      _approvedUsers = users;
      _isLoading = false;
    });
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'assets/images/profiles/default_profile.png';
    if (path.startsWith('http') || path.startsWith('https')) return path;
    if (path.startsWith('/storage/')) return backendBaseUrl + path;
    return path;
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
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Chats'), Tab(text: 'Contacts')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Chats tab
                ListView.builder(
                  itemCount: _conversations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: const Text('Saved Messages'),
                        subtitle: const Text('Your personal notes'),
                        onTap: () async {
                          final saved = await authService.fetchSavedMessages();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatConversationScreen(
                                userName: 'Saved Messages',
                                userImage: '',
                                conversationId: saved['conversation_id'],
                                receiverId: currentUserId!,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                      );
                    }

                    final conv = _conversations[index - 1];
                    final isUserOne = conv['user_one_id'] == currentUserId;
                    final otherUser = isUserOne ? conv['user_two'] : conv['user_one'];
                    final otherUserId = isUserOne
                        ? conv['user_two_id']
                        : conv['user_one_id'];
                    final userName = otherUser?['name'] ?? 'User';
                    final userImage = otherUser?['profile_picture'] ?? '';
                    final lastMessage = conv['last_message']?['message'] ?? 'No messages yet';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userImage.isNotEmpty
                            ? NetworkImage(getFullImageUrl(userImage))
                            : const AssetImage('assets/images/profiles/default_profile.png')
                                as ImageProvider,
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
                ),

                // Contacts tab
                ListView.builder(
                  itemCount: _approvedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _approvedUsers[index];
                    if (user['id'] == currentUserId) return const SizedBox.shrink();

                    final existingConv = _conversations.firstWhere(
                      (conv) =>
                          (conv['user_one_id'] == currentUserId &&
                              conv['user_two_id'] == user['id']) ||
                          (conv['user_two_id'] == currentUserId &&
                              conv['user_one_id'] == user['id']),
                      orElse: () => <String, dynamic>{},
                    );
                    final convId = existingConv['id'] ?? 0;
                    final lastMessage = existingConv['last_message']?['message'] ??
                        user['email'] ??
                        'No messages yet';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profile_picture'] != null
                            ? NetworkImage(getFullImageUrl(user['profile_picture']))
                            : const AssetImage('assets/images/profiles/default_profile.png')
                                as ImageProvider,
                      ),
                      title: Text(user['name'] ?? 'User'),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatConversationScreen(
                              userName: user['name'] ?? 'User',
                              userImage: user['profile_picture'] ?? '',
                              conversationId: convId,
                              receiverId: user['id'],
                              currentUserId: currentUserId!,
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
