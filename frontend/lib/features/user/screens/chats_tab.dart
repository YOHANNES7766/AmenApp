import 'package:flutter/material.dart';
import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';

const String backendBaseUrl = 'https://amenapp-production.up.railway.app';

class ChatsTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> conversationsFuture;
  final int currentUserId;
  final AuthService authService;

  const ChatsTab({
    Key? key,
    required this.conversationsFuture,
    required this.currentUserId,
    required this.authService,
  }) : super(key: key);

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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading conversations...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Failed to load conversations', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('${snapshot.error}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => authService.fetchConversations(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No conversations yet', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Start a conversation from the Contacts tab', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final conversations = snapshot.data ?? [];
        final filteredConversations = conversations.where((conversation) {
          final otherUserId = conversation['user_one_id'] == currentUserId
              ? conversation['user_two_id']
              : conversation['user_one_id'];
          return otherUserId != currentUserId;
        }).toList();

        if (filteredConversations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No conversations yet', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Start a conversation from the Contacts tab', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            final otherUser = conversation['user_one_id'] == currentUserId
                ? conversation['user_two'] ?? {}
                : conversation['user_one'] ?? {};

            final userId = otherUser['id'] ?? 0;
            final userName = otherUser['name'] ?? 'User';
            final userImage = otherUser['profile_picture'];
            final lastMessage = conversation['last_message']?['message'] ?? 'No messages yet';

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userImage != null && userImage.isNotEmpty
                    ? NetworkImage(getFullImageUrl(userImage))
                    : const AssetImage('assets/images/profiles/default_profile.png') as ImageProvider,
              ),
              title: Text(userName),
              subtitle: Text(lastMessage),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatConversationScreen(
                      userName: userName,
                      userImage: getFullImageUrl(userImage),
                      conversationId: conversation['id'] ?? 0,
                      receiverId: userId,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
