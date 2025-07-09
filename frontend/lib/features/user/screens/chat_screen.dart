import 'package:flutter/material.dart';
import '../../admin/screens/admin_chat_screen.dart';
import 'chat_conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // Use the same widget as admin for unified experience
    return const AdminChatScreen();
  }
}
