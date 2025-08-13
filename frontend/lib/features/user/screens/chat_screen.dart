import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';
import 'chats_tab.dart';

const String backendBaseUrl = 'https://amenapp-production.up.railway.app';

ImageProvider getProfileImage(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return const AssetImage('assets/images/profiles/default_profile.png');
  }
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return NetworkImage(imagePath);
  }
  if (imagePath.startsWith('/storage/')) {
    return NetworkImage(backendBaseUrl + imagePath);
  }
  return AssetImage(imagePath);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<List<Map<String, dynamic>>> _conversationsFuture; // Chats
  late Future<List<Map<String, dynamic>>> _allUsersFuture;     // Contacts

  late PusherChannelsFlutter _pusher;
  final Set<int> _subscribedConversationIds = {};

  int? currentUserId;
  String? _authToken;

  bool _pusherInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final authService = Provider.of<AuthService>(context, listen: false);
    currentUserId = authService.currentUserId;
    _authToken = authService.accessToken;

    _conversationsFuture = authService.fetchConversations();
    _allUsersFuture = authService.fetchApprovedUsers();

    _preparePusherAndSubscribe();
  }

  Future<void> _preparePusherAndSubscribe() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _authToken = authService.accessToken;

    _pusher = PusherChannelsFlutter();

    await _pusher.init(
      apiKey: '4c83807283760dab1b1d',
      cluster: 'mt1',
      authEndpoint: '$backendBaseUrl/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        return {
          'headers': {
            'Authorization': 'Bearer ${_authToken ?? ''}',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          }
        };
      },
      onEvent: _handlePusherEvent,
    );

    await _pusher.connect();

    try {
      final convList = await Provider.of<AuthService>(context, listen: false).fetchConversations();
      for (final conv in convList) {
        final id = conv['id'];
        if (id is int) await _subscribeToConversationChannel(id);
      }
    } catch (e) {
      debugPrint('Error fetching conversations for pusher subscriptions: $e');
    }

    setState(() {
      _pusherInitialized = true;
    });
  }

  Future<void> _subscribeToConversationChannel(int conversationId) async {
    if (_subscribedConversationIds.contains(conversationId)) return;

    final channelName = 'private-conversation.$conversationId';
    try {
      await _pusher.subscribe(channelName: channelName);
      _subscribedConversationIds.add(conversationId);
      debugPrint('Subscribed to $channelName');
    } catch (e) {
      debugPrint('Failed to subscribe to $channelName : $e');
    }
  }

  void _handlePusherEvent(PusherEvent event) {
    if (event.eventName != 'MessageSent') return;

    try {
      final data = jsonDecode(event.data ?? '{}');
      final message = data['message'];
      if (message == null) return;

      final senderId = message['sender_id'];
      final receiverId = message['receiver_id'];
      final convId = message['conversation_id'];

      if (senderId == currentUserId || receiverId == currentUserId) {
        _refreshConversations();
        if (convId is int) _subscribeToConversationChannel(convId);
      }
    } catch (e) {
      debugPrint('Error parsing pusher event: $e');
    }
  }

  void _refreshConversations() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _conversationsFuture = authService.fetchConversations();
    });

    _conversationsFuture.then((convs) {
      for (final conv in convs) {
        final id = conv['id'];
        if (id is int) _subscribeToConversationChannel(id);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    try {
      for (final id in _subscribedConversationIds) {
        final channelName = 'private-conversation.$id';
        _pusher.unsubscribe(channelName: channelName);
      }
      _pusher.disconnect();
    } catch (e) {
      debugPrint('Error during pusher cleanup: $e');
    }

    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            if (!_pusherInitialized)
              Container(
                width: double.infinity,
                color: Colors.yellow[50],
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: const Text('Connecting for real-time updates...',
                    style: TextStyle(fontSize: 12)),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Chats tab
                  ChatsTab(
                    conversationsFuture: _conversationsFuture,
                    currentUserId: nonNullUserId,
                    authService: authService,
                  ),

                  // Contacts tab
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _allUsersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final users = snapshot.data!
                          .where((u) => u['id'] != nonNullUserId)
                          .toList();

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userName = user['name'] ?? 'User';
                          final userImage = user['profile_picture'] ?? '';
                          final userId = user['id'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: getProfileImage(userImage),
                              child: userImage.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userName),
                            onTap: () async {
                              // find conversationId if exists
                              final existingConv = await _conversationsFuture.then(
                                (convs) => convs.firstWhere(
                                  (conv) =>
                                      (conv['user_one_id'] == nonNullUserId &&
                                          conv['user_two_id'] == userId) ||
                                      (conv['user_two_id'] == nonNullUserId &&
                                          conv['user_one_id'] == userId),
                                  orElse: () => <String, dynamic>{},
                                ),
                              );

                              final conversationId = existingConv['id'] ?? 0;

                              await Navigator.push(
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

                              _refreshConversations();
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
