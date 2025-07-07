import 'package:flutter/material.dart';
import 'chat_conversation_screen.dart';

class CustomAvatar extends StatelessWidget {
  final String imagePath;
  final double size;
  final bool isStory;
  final String fallbackImage;

  static const String defaultProfileImage =
      'assets/images/profiles/default_profile.png';
  static const String defaultGroupImage =
      'assets/images/profiles/default_group.png';

  const CustomAvatar({
    Key? key,
    required this.imagePath,
    this.size = 40.0,
    this.isStory = false,
    this.fallbackImage = defaultProfileImage,
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
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              fallbackImage,
              fit: BoxFit.cover,
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
          },
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _showChats = true;
  bool _isLoading = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  final List<String> userProfileImages = [
    'assets/images/profiles/user1.jpg',
    'assets/images/profiles/user2.jpg',
    'assets/images/profiles/user3.jpg',
    'assets/images/profiles/user4.jpg',
    'assets/images/profiles/user5.jpg',
  ];

  final List<String> groupProfileImages = [
    'assets/images/profiles/group1.jpg',
    'assets/images/profiles/group2.jpg',
    'assets/images/profiles/group3.jpg',
    'assets/images/profiles/group4.jpg',
    'assets/images/profiles/group5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Error loading chats: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load chats: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // Add your logic here for "Your Story" tap
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(color: Colors.grey[400]!, width: 1.5),
              ),
              child: const Icon(Icons.add, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your Story',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(String imagePath, int index, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          const Text('Avatar'),
          const SizedBox(height: 6),
          Text(
            isUser ? 'User $index' : 'Group $index',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    return ListView.builder(
      itemCount: 10,
      cacheExtent: 200,
      itemBuilder: (context, index) {
        final imageIndex = index % userProfileImages.length;
        return ListTile(
          key: ValueKey('chat_$index'),
          leading: const Text('Avatar'),
          title: Text('${index + 1} User'),
          subtitle: const Text('Last message...'),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${index + 1}:00 PM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
                  userImage: userProfileImages[imageIndex],
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
      cacheExtent: 200,
      itemBuilder: (context, index) {
        return ListTile(
          key: ValueKey('group_$index'),
          leading: const Text('Avatar'),
          title: Text('${index + 1} Group'),
          subtitle: const Text('Last group message...'),
          trailing: Text(
            '${index + 1}:00 PM',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          onTap: () {
            // TODO: Handle group tap
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Stories section
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: userProfileImages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddStoryButton();
                return _buildStoryItem(
                    userProfileImages[index - 1], index - 1, true);
              },
            ),
          ),
          const Divider(height: 1),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
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
                          'Groups',
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
                          'Chats',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : (_showChats ? _buildChatsTab() : _buildGroupsTab()),
          ),
        ],
      ),
    );
  }
}
