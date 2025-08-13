import 'package:flutter/material.dart';
import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No conversations yet.'));
        }

        final filteredConversations = snapshot.data!.where((conversation) {
          final otherUserId = conversation['user_one_id'] == currentUserId
              ? conversation['user_two_id']
              : conversation['user_one_id'];
          return otherUserId != currentUserId;
        }).toList();

        return ListView.builder(
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
