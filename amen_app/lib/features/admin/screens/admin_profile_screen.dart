import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/theme_service.dart';
import '../../../core/localization/app_localizations.dart';
import 'user_management.dart';
import 'content_management.dart';
import 'event_management.dart';
import 'prayer_moderation.dart';
import 'commentary_moderation.dart';
import 'notification_control.dart';
import 'feedback_management.dart';
import 'app_settings.dart';
import 'analytics_dashboard.dart';
import 'attendance_management.dart';

class AdminProfileScreen extends StatelessWidget {
  final bool isTab;
  const AdminProfileScreen({Key? key, this.isTab = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminProfileContent(isTab: isTab);
  }
}

class AdminProfileContent extends StatelessWidget {
  final bool isTab;
  const AdminProfileContent({Key? key, this.isTab = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: isTab
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/admin');
                  }
                },
              ),
              title: Text(localizations.profile),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Handle app settings
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle profile picture change
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: Text(localizations.takePhoto),
                              onTap: () {
                                Navigator.pop(context);
                                // Handle camera
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: Text(localizations.chooseFromGallery),
                              onTap: () {
                                Navigator.pop(context);
                                // Handle gallery selection
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(
                              'assets/images/profiles/user1.png.jpg'),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.admin,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'admin@amenapp.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle edit profile
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(localizations.editProfile),
                  ),
                ],
              ),
            ),
            // Admin Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.adminDashboard,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, localizations.totalUsers, '241'),
                      _buildStatItem(context, localizations.content, '56'),
                      _buildStatItem(context, localizations.events, '12'),
                    ],
                  ),
                ],
              ),
            ),
            // Admin Menu Items
            _buildSection(
              title: localizations.userManagement,
              children: [
                _buildMenuItem(
                  icon: Icons.people,
                  title: localizations.userManagement,
                  subtitle: localizations.manageEfficiently,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagement(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today,
                  title: localizations.attendanceList,
                  subtitle: localizations.trackAttendance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceManagement(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.person_pin_circle,
                  title: localizations.prayerModeration,
                  subtitle: localizations.prayerRequests,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrayerModeration(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.comment,
                  title: localizations.commentaryModeration,
                  subtitle: localizations.commentary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommentaryModeration(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: localizations.contentManagement,
              children: [
                _buildMenuItem(
                  icon: Icons.book,
                  title: localizations.contentManagement,
                  subtitle: localizations.content,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContentManagement(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.event,
                  title: localizations.eventManagement,
                  subtitle: localizations.events,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventManagement(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: localizations.notificationControl,
                  subtitle: localizations.notifications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationControl(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: localizations.appSettings,
              children: [
                _buildMenuItem(
                  icon: Icons.feedback,
                  title: localizations.feedbackManagement,
                  subtitle: localizations.feedback,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackManagement(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: localizations.appSettings,
                  subtitle: localizations.settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppSettings(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: localizations.analyticsDashboard,
                  subtitle: localizations.analytics,
                  onTap: () {
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
            _buildMenuItem(
              icon: Icons.logout,
              title: localizations.logout,
              subtitle: localizations.logout,
              onTap: () {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                authService.logout().then((_) {
                  Navigator.pushReplacementNamed(context, '/login');
                });
              },
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
