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
  List<Map<String, dynamic>>? _conversations;
  List<Map<String, dynamic>>? _approvedUsers;
  bool _isLoadingChats = true;
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);

      authService.fetchConversations().then((data) {
        setState(() {
          _conversations = data;
          _isLoadingChats = false;
        });
      });

      authService.fetchApprovedUsers().then((data) {
        setState(() {
          _approvedUsers = data;
          _isLoadingContacts = false;
        });
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
    final currentUserId = authService.currentUserId;
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
                  // Chats Tab
                  _isLoadingChats
                      ? const Center(child: CircularProgressIndicator())
                      : _conversations == null || _conversations!.isEmpty
                          ? const Center(child: Text('No conversations found.'))
                          : ListView.builder(
                              itemCount: _conversations!.length + 1,
                              itemBuilder: (context, index) {
                                final conversations = _conversations!
                                    .where((conv) =>
                                        conv['user_one_id'] != currentUserId ||
                                        conv['user_two_id'] != currentUserId)
                                    .toList();

                                if (index == 0) {
                                  return ListTile(
                                    leading: const Icon(Icons.bookmark,
                                        color: Colors.blue, size: 40),
                                    title: const Text('Saved Messages'),
                                    subtitle:
                                        const Text('Your personal notes'),
                                    onTap: () async {
                                      try {
                                        final data = await authService
                                            .fetchSavedMessages();
                                        final conversationId =
                                            data['conversation_id'];
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatConversationScreen(
                                              userName: 'Saved Messages',
                                              userImage: '',
                                              conversationId: conversationId,
                                              receiverId: currentUserId!,
                                              currentUserId: currentUserId,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Failed to open Saved Messages: $e')),
                                        );
                                      }
                                    },
                                  );
                                }

                                final conv = conversations[index - 1];
                                final userOne = conv['user_one'];
                                final userTwo = conv['user_two'];
                                final isUserOne =
                                    conv['user_one_id'] == currentUserId;
                                final otherUser =
                                    isUserOne ? userTwo : userOne;
                                final otherUserId = isUserOne
                                    ? conv['user_two_id']
                                    : conv['user_one_id'];
                                final userName =
                                    otherUser?['name'] ?? 'User';
                                final userImage =
                                    otherUser?['profile_picture'] ?? '';
                                final lastMessage = conv['last_message']?
                                        ['message'] ??
                                    'No messages yet';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: userImage.isNotEmpty
                                        ? (userImage.startsWith('http') ||
                                                userImage
                                                    .startsWith('/storage/')
                                            ? NetworkImage(
                                                getFullImageUrl(userImage))
                                            : AssetImage(
                                                    getFullImageUrl(userImage))
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
                                        builder: (context) =>
                                            ChatConversationScreen(
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

                  // Contacts Tab
                  _isLoadingContacts
                      ? const Center(child: CircularProgressIndicator())
                      : _approvedUsers == null || _approvedUsers!.isEmpty
                          ? const Center(child: Text('No approved users found.'))
                          : ListView.builder(
                              itemCount: _approvedUsers!.length,
                              itemBuilder: (context, index) {
                                final user = _approvedUsers![index];
                                final userId = user['id'];
                                final userName = user['name'] ?? 'User';
                                final userImage = user['profile_picture'] ?? '';
                                final existingConv = _conversations?.firstWhere(
                                      (conv) =>
                                          (conv['user_one_id'] ==
                                                  currentUserId &&
                                              conv['user_two_id'] == userId) ||
                                          (conv['user_two_id'] ==
                                                  currentUserId &&
                                              conv['user_one_id'] == userId),
                                      orElse: () => <String, dynamic>{},
                                    ) ??
                                    {};
                                final conversationId =
                                    (existingConv.isNotEmpty &&
                                            existingConv.containsKey('id'))
                                        ? existingConv['id']
                                        : 0;
                                final lastMessage =
                                    existingConv['last_message']?['message'] ??
                                        (user['email'] ?? 'No messages yet');

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: userImage.isNotEmpty
                                        ? (userImage.startsWith('http') ||
                                                userImage
                                                    .startsWith('/storage/')
                                            ? NetworkImage(
                                                getFullImageUrl(userImage))
                                            : AssetImage(
                                                    getFullImageUrl(userImage))
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
                                        builder: (context) =>
                                            ChatConversationScreen(
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