import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'language_screen.dart';
import 'joined_events_screen.dart';
import 'theme_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Change app theme'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('Change app language'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Joined Events'),
            subtitle: const Text('View your joined events'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinedEventsScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('Manage privacy settings'),
            onTap: () {
              // TODO: Implement privacy settings
            },
          ),
        ],
      ),
    );
  }
}
