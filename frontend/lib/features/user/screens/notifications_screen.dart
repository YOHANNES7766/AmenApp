import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Daily Devotion Reminders'),
            subtitle: const Text('Get notified for daily devotions'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Bible Study Schedule'),
            subtitle: const Text('Get notified for upcoming bible studies'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Prayer Requests'),
            subtitle: const Text('Get notified for new prayer requests'),
            value: true,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
