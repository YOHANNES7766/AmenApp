import 'package:flutter/material.dart';

class JoinedEventsScreen extends StatelessWidget {
  const JoinedEventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Joined Events'),
      ),
      body: const Center(
        child: Text('Your joined events will appear here'),
      ),
    );
  }
}
