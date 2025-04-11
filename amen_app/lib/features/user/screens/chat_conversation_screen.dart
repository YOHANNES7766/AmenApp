import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatConversationScreen extends StatefulWidget {
  final String userName;
  final String userImage;

  const ChatConversationScreen({
    Key? key,
    required this.userName,
    required this.userImage,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add some sample messages
    _messages.addAll([
      Message(
        text: "off at your place, hope you like it!!",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Message(
        text: "Thanks so much man! 🙏",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Message(
        text:
            "Do you think you will be able to make it to the presentation tomorrow? I think it would be helpful for the team if you are there to support them.",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      Message(
        text: "Yes I should be able to make it!",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Message(
        text: "What time is it at again?",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      Message(
        text: "2:30, but I don't think it'll start then",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      Message(
        text: "Probably more like 3pm",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 19)),
      ),
      Message(
        text: "Thanks again for coming 😊",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Message(
        text: "Hey! Are you free to call tonight?",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: _messageController.text.trim(),
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.userImage),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final showTimestamp = index == _messages.length - 1 ||
                    _messages[index + 1].isMe != message.isMe;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: message.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!message.isMe && showTimestamp)
                        CircleAvatar(
                          backgroundImage: AssetImage(widget.userImage),
                          radius: 16,
                        ),
                      if (!message.isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: message.isMe
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
