import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../shared/services/auth_service.dart';
import 'chat_conversation_screen.dart';
import 'chats_tab.dart';

// Make sure backendBaseUrl is defined somewhere accessible in your app.
const String backendBaseUrl = 'https://your-backend.example.com';

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

  // Futures for initial UI (conversations/contacts)
  late Future<List<Map<String, dynamic>>> _conversationsFuture;
  late Future<List<Map<String, dynamic>>> _approvedUsersFuture;

  // Pusher client
  late PusherChannelsFlutter _pusher;
  // track which conversation channels we've subscribed to
  final Set<int> _subscribedConversationIds = {};

  // current user
  int? currentUserId;

  // for auth headers when authorizing private channels
  String? _authToken;

  bool _pusherInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Use listen: false because we only need values now
    final authService = Provider.of<AuthService>(context, listen: false);
    currentUserId = authService.currentUserId;
    _authToken = authService.accessToken;

    // kick off fetching data and pusher init
    _conversationsFuture = authService.fetchConversations();
    _approvedUsersFuture = authService.fetchApprovedUsers();

    // initialize pusher after fetching conversations so we can subscribe to channels
    _preparePusherAndSubscribe();
  }

  Future<void> _preparePusherAndSubscribe() async {
    // ensure auth token is up-to-date
    final authService = Provider.of<AuthService>(context, listen: false);
    _authToken = authService.accessToken;

    // initialize pusher client
    _pusher = PusherChannelsFlutter();

    await _pusher.init(
      apiKey: '4c83807283760dab1b1d', // keep your key or move to config
      cluster: 'mt1',
      authEndpoint: '$backendBaseUrl/broadcasting/auth',
      // Authorizer provides headers needed by Laravel broadcasting auth endpoint
      onAuthorizer: (channelName, socketId, options) async {
        // Provide Bearer token and necessary headers
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

    // connect (will be used for all subscriptions)
    await _pusher.connect();

    // fetch conversations now (in case initial future already resolved)
    try {
      final convList = await Provider.of<AuthService>(context, listen: false)
          .fetchConversations();

      // expect convList to be List<Map<String, dynamic>> where each has 'id'
      for (final conv in convList) {
        final id = conv['id'];
        if (id is int) {
          await _subscribeToConversationChannel(id);
        }
      }
    } catch (e) {
      // ignore if fetch fails here — UI will handle errors via _conversationsFuture
      debugPrint('Error fetching conversations for pusher subscriptions: $e');
    }

    setState(() {
      _pusherInitialized = true;
    });
  }

  // subscribe to a private conversation channel only once
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

  // handle incoming pusher events
  void _handlePusherEvent(PusherEvent event) {
    // We expect backend broadcastAs() => 'MessageSent'
    if (event.eventName != 'MessageSent') return;

    try {
      final data = jsonDecode(event.data ?? '{}');
      final message = data['message'];
      if (message == null) return;

      final senderId = message['sender_id'];
      final receiverId = message['receiver_id'];
      final convId = message['conversation_id'];

      // If the event is related to current user, refresh conversations
      if (senderId == currentUserId || receiverId == currentUserId) {
        _refreshConversations();

        // ensure we are subscribed to this conversation channel if not yet
        if (convId is int) {
          _subscribeToConversationChannel(convId);
        }
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

    // After refreshing conversations, re-subscribe to any new conversation channels
    _conversationsFuture.then((convs) {
      for (final conv in convs) {
        final id = conv['id'];
        if (id is int) _subscribeToConversationChannel(id);
      }
    }).catchError((_) {
      // ignore errors here; UI handles them
    });
  }

  @override
  void dispose() {
    // unsubscribe/disconnect pusher safely
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
            // show a small indicator if pusher isn't ready yet (optional)
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
                  ChatsTab(
                    conversationsFuture: _conversationsFuture,
                    currentUserId: nonNullUserId,
                    authService: authService,
                  ),
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
                      }

                      final approvedUsers = snapshot.data![0] as List<Map<String, dynamic>>;
                      final conversations = snapshot.data![1] as List<Map<String, dynamic>>;

                      final users = approvedUsers.where((user) => user['id'] != nonNullUserId).toList();

                      // ensure we subscribe to any conversation IDs encountered here
                      for (final conv in conversations) {
                        final id = conv['id'];
                        if (id is int) _subscribeToConversationChannel(id);
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userName = user['name'] ?? 'User';
                          final userImage = user['profile_picture'] ?? '';
                          final userId = user['id'];

                          final existingConv = conversations.firstWhere(
                            (conv) =>
                                (conv['user_one_id'] == nonNullUserId && conv['user_two_id'] == userId) ||
                                (conv['user_two_id'] == nonNullUserId && conv['user_one_id'] == userId),
                            orElse: () => <String, dynamic>{},
                          );

                          final conversationId = existingConv['id'] ?? 0;

                          final lastMessage = (existingConv['last_message'] != null)
                              ? (existingConv['last_message']['message'] ?? 'No messages yet')
                              : 'Start a conversation';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: getProfileImage(userImage),
                              child: userImage.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userName),
                            subtitle: Text(lastMessage),
                            onTap: () async {
                              // If conversationId == 0, the ChatConversationScreen will create it on send
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

                              // after returning from conversation, refresh list
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
