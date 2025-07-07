import 'package:flutter/material.dart';
import '../../user/screens/chat_conversation_screen.dart';
import '../../../core/localization/app_localizations.dart';

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
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(), // Optimize memory usage
          cacheHeight: (size * 2).toInt(),
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
        ),
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  bool _showChats = true;

  // Profile images - using simpler, more reliable image paths
  final List<String> _userProfileImages = [
    'assets/images/profiles/user1.jpg',
    'assets/images/profiles/user2.jpg',
    'assets/images/profiles/user3.jpg',
    'assets/images/profiles/user4.jpg',
    'assets/images/profiles/user5.jpg',
  ];

  final List<String> _groupProfileImages = [
    'assets/images/profiles/group1.jpg',
    'assets/images/profiles/group2.jpg',
    'assets/images/profiles/group3.jpg',
    'assets/images/profiles/group4.jpg',
    'assets/images/profiles/group5.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.chat),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories section
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Add story button
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.add,
                                size: 24, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.add,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Sample story avatars
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          CustomAvatar(
                            imagePath: _userProfileImages[index],
                            size: 60,
                            isStory: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${index + 1} ${localizations.user}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Custom Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showChats = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: !_showChats
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          localizations.groups,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_showChats
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            fontWeight: !_showChats
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showChats = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _showChats
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          localizations.users,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showChats
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            fontWeight: _showChats
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _showChats ? _buildUsersTab() : _buildGroupsTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to create new chat or group
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_showChats ? 'New User Chat' : 'New Group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showChats) ...[
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Members:'),
                    // Add member selection here
                  ] else ...[
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Search User',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select User:'),
                    // Add user selection here
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Handle creation
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: 10,
      // Add cacheExtent to improve scrolling performance
      cacheExtent: 200,
      itemBuilder: (context, index) {
        final imageIndex = index % _userProfileImages.length;
        return ListTile(
          key: ValueKey(
              'admin_user_$index'), // Add unique key for better performance
          leading: CustomAvatar(
            imagePath: _userProfileImages[imageIndex],
            size: 40,
          ),
          title: Text('${index + 1} User'),
          subtitle: const Text('Last message...'),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${index + 1}:00 PM',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              if (index % 3 == 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatConversationScreen(
                  userName: '${index + 1} User',
                  userImage: _userProfileImages[imageIndex],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return ListView.builder(
      itemCount: 5,
      // Add cacheExtent to improve scrolling performance
      cacheExtent: 200,
      itemBuilder: (context, index) {
        return ListTile(
          key: ValueKey(
              'admin_group_$index'), // Add unique key for better performance
          leading: CustomAvatar(
            imagePath: _groupProfileImages[index],
            size: 40,
          ),
          title: Text('${index + 1} Group'),
          subtitle: const Text('Last group message...'),
          trailing: Text(
            '${index + 1}:00 PM',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatConversationScreen(
                  userName: '${index + 1} Group',
                  userImage: _groupProfileImages[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
