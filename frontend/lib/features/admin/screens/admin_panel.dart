import 'package:flutter/material.dart';
import 'package:amen_app/features/admin/screens/user_management.dart';
import 'package:amen_app/features/admin/screens/content_management.dart';
import 'package:amen_app/features/admin/screens/event_management.dart';
import 'package:amen_app/features/admin/screens/prayer_moderation.dart';
import 'package:amen_app/features/admin/screens/commentary_moderation.dart';
import 'package:amen_app/features/admin/screens/notification_control.dart';
import 'package:amen_app/features/admin/screens/feedback_management.dart';
import 'package:amen_app/features/admin/screens/app_settings.dart';
import 'package:amen_app/features/admin/screens/analytics_dashboard.dart';
import 'package:amen_app/features/admin/widgets/admin_drawer.dart';
import 'package:amen_app/features/admin/screens/admin_home_screen.dart';
import 'package:amen_app/core/localization/app_localizations.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const AdminHomeContent(),
    const UserManagement(),
    const ContentManagement(),
    const EventManagement(),
    const PrayerModeration(),
    const CommentaryModeration(),
    const NotificationControl(),
    const FeedbackManagement(),
    const AppSettings(),
    const AnalyticsDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminDashboard),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: AdminDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
      body: _screens[_selectedIndex],
    );
  }
}
