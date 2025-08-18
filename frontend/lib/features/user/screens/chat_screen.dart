import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<List<Map<String, dynamic>>>? _conversationsFuture; // Chats
  Future<List<Map<String, dynamic>>>? _allUsersFuture;     // Contacts

  late PusherChannelsFlutter _pusher;
  final Set<int> _subscribedConversationIds = {};

  int? currentUserId;
  String? _authToken;

  bool _pusherInitialized = false;
  
  // Cache for instant loading
  List<Map<String, dynamic>> _cachedConversations = [];
  List<Map<String, dynamic>> _cachedUsers = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final authService = Provider.of<AuthService>(context, listen: false);
    currentUserId = authService.currentUserId;
    _authToken = authService.accessToken;

    _loadChatData();
    _preparePusherAndSubscribe();
  }

  Future<void> _loadChatData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Always show cached data immediately for instant loading
    setState(() {
      _conversationsFuture = Future.value(_cachedConversations);
      _allUsersFuture = Future.value(_cachedUsers);
    });
    
    // Fetch fresh data in background
    _fetchFreshData();
  }
  
  Future<void> _fetchFreshData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Fetch both conversations and users in parallel for faster loading
      final results = await Future.wait([
        authService.fetchConversations().timeout(
          const Duration(seconds: 5),
          onTimeout: () => _cachedConversations,
        ),
        authService.fetchApprovedUsers().timeout(
          const Duration(seconds: 5), 
          onTimeout: () => _cachedUsers,
        ),
      ]);
      
      final conversations = results[0] as List<Map<String, dynamic>>;
      final users = results[1] as List<Map<String, dynamic>>;
      
      // Update cache and UI
      if (mounted) {
        setState(() {
          _cachedConversations = conversations;
          _cachedUsers = users;
          _conversationsFuture = Future.value(conversations);
          _allUsersFuture = Future.value(users);
        });
        debugPrint('✅ Updated conversations: ${conversations.length}, users: ${users.length}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching fresh data: $e');
      // Keep showing cached data on error
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _preparePusherAndSubscribe() async {
    try {
      _pusher = PusherChannelsFlutter();

      await _pusher.init(
        apiKey: '4c83807283760dab1b1d',
        cluster: 'mt1',
        authEndpoint: '$backendBaseUrl/api/broadcasting/auth',
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
      ).timeout(const Duration(seconds: 5));

      await _pusher.connect().timeout(const Duration(seconds: 5));
      debugPrint('✅ Pusher connected successfully');
      
      setState(() {
        _pusherInitialized = true;
      });

      _subscribeToExistingConversations();
    } catch (e) {
      debugPrint('❌ Pusher connection failed: $e');
      setState(() {
        _pusherInitialized = true; // Allow UI to continue
      });
    }
  }

  Future<void> _subscribeToExistingConversations() async {
    try {
      if (_conversationsFuture == null) {
        debugPrint('⚠️ Conversations future not initialized yet');
        return;
      }
      
      final convList = await _conversationsFuture!.timeout(const Duration(seconds: 5));
      for (final conv in convList) {
        final id = conv['id'];
        if (id is int) {
          await _subscribeToConversationChannel(id);
        }
      }
      debugPrint('✅ Subscribed to ${_subscribedConversationIds.length} conversations');
    } catch (e) {
      debugPrint('❌ Error subscribing to conversations: $e');
    }
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
    _fetchFreshData();
  }
  
  Future<void> _onRefresh() async {
    await _fetchFreshData();
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
                  // Chats Tab
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ChatsTab(
                      conversationsFuture: _conversationsFuture ?? Future.value(<Map<String, dynamic>>[]),
                      currentUserId: nonNullUserId,
                      authService: authService,
                    ),
                  ),
                  // Contacts Tab
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
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
                                final existingConv = await (_conversationsFuture ?? Future.value(<Map<String, dynamic>>[])).then(
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
