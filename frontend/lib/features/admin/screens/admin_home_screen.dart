import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import 'user_management.dart';
import 'content_management.dart';
import 'event_management.dart';
import 'prayer_moderation.dart';
import 'analytics_dashboard.dart';
import 'commentary_moderation.dart';
import 'notification_control.dart';
import 'feedback_management.dart';
import 'app_settings.dart';
import 'admin_chat_screen.dart';
import 'admin_books_screen.dart';
import 'admin_profile_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/language_selector.dart';

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.welcomeAdmin,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.manageEfficiently,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Text(
            localizations.quickStats,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                localizations.totalUsers,
                '241',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                localizations.activeUsers,
                '134',
                Icons.people_alt,
                Colors.green,
              ),
              _buildStatCard(
                context,
                localizations.prayerRequests,
                '56',
                Icons.person_pin_circle,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                localizations.events,
                '12',
                Icons.event,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            localizations.quickActions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionButton(
                context,
                localizations.userManagement,
                Icons.people,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagement(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                localizations.contentManagement,
                Icons.article,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContentManagement(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                localizations.prayerModeration,
                Icons.person_pin_circle,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrayerModeration(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                localizations.analyticsDashboard,
                Icons.analytics,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsDashboard(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
    const AdminChatScreen(),
    AdminBooksScreen(),
    const AdminProfileScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    print('Building AdminHomeScreen with _selectedIndex: $_selectedIndex');

    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle(localizations)),
        actions: [
          ..._getAppBarActions(),
          // Add language selector
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      drawer: AdminDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _getFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getBottomNavIndex(_selectedIndex),
        onTap: (index) {
          print('Bottom nav tab $index tapped');
          if (index == 2) {
            // Books tab
            print('Books tab clicked, directly setting to AdminBooksScreen');
            setState(() {
              _selectedIndex = 11; // AdminBooksScreen
            });
          } else {
            final screenIndex = _getScreenIndexFromBottomNav(index);
            print('Setting _selectedIndex to $screenIndex');
            setState(() {
              _selectedIndex = screenIndex;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localizations.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: localizations.chat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: localizations.books,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: localizations.profile,
          ),
        ],
      ),
    );
  }

  String _getScreenTitle(AppLocalizations localizations) {
    switch (_selectedIndex) {
      case 0:
        return localizations.adminDashboard;
      case 1:
        return localizations.userManagement;
      case 2:
        return localizations.contentManagement;
      case 3:
        return localizations.eventManagement;
      case 4:
        return localizations.prayerModeration;
      case 5:
        return localizations.commentaryModeration;
      case 6:
        return localizations.notificationControl;
      case 7:
        return localizations.feedbackManagement;
      case 8:
        return localizations.appSettings;
      case 9:
        return localizations.analyticsDashboard;
      case 10:
        return localizations.chat;
      case 11:
        return localizations.books;
      case 12:
        return localizations.profile;
      default:
        return localizations.adminDashboard;
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_selectedIndex) {
      case 1: // User Management
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              UserManagement.refreshUsers(context);
            },
          ),
        ];
      default:
        return [];
    }
  }

  Widget? _getFloatingActionButton() {
    final localizations = AppLocalizations.of(context);

    switch (_selectedIndex) {
      default:
        return null;
    }
  }

  // Helper method to convert screen index to bottom nav index
  int _getBottomNavIndex(int screenIndex) {
    switch (screenIndex) {
      case 0: // Home
        return 0;
      case 10: // Chat
        return 1;
      case 11: // Books
        return 2;
      case 12: // Profile
        return 3;
      default:
        return 0;
    }
  }

  // Helper method to convert bottom nav index to screen index
  int _getScreenIndexFromBottomNav(int bottomNavIndex) {
    print('Converting bottom nav index $bottomNavIndex to screen index');
    switch (bottomNavIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 10; // Chat
      case 2:
        print(
            'Books tab clicked, returning screen index 11 (AdminBooksScreen)');
        return 11; // Books
      case 3:
        return 12; // Profile
      default:
        return 0;
    }
  }
}
