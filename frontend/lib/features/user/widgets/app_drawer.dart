import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amen_app/shared/services/auth_service.dart';
import 'package:amen_app/features/user/screens/profile_screen.dart';
import 'package:amen_app/features/user/screens/prayer_requests_screen.dart';
import 'package:amen_app/features/user/screens/completed_devotions_screen.dart';
import 'package:amen_app/features/user/screens/settings_screens.dart';
import 'package:amen_app/features/user/screens/saved_notes_screen.dart';
import 'package:amen_app/features/user/screens/joined_events_screen.dart';
import 'package:amen_app/features/user/screens/language_screen.dart';
import 'package:amen_app/features/user/screens/notifications_screen.dart';
import 'package:amen_app/features/user/screens/attendance_screen.dart';
import 'package:amen_app/shared/services/theme_service.dart';
import 'package:amen_app/core/localization/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final localizations = AppLocalizations.of(context);

    return Drawer(
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.only(
                  top: 50, bottom: 16, left: 16, right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage:
                        const AssetImage('assets/images/profiles/jo.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jo',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'yohannesdawit360@gmail.com',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: localizations.profile,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(isTab: false),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.comment_outlined,
                    title: localizations.commentary,
                    onTap: () {
                      // TODO: Implement commentary screen navigation
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: localizations.settings,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppSettingsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: localizations.notifications,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.front_hand_outlined,
                    title: localizations.myPrayers,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrayerRequestsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.check_circle_outline,
                    title: localizations.completedDevotions,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletedDevotionsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.book_outlined,
                    title: localizations.savedNotes,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedNotesScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.event_outlined,
                    title: localizations.joinedEvents,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinedEventsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: localizations.attendance,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.language,
                    title: localizations.languageSelector,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageScreen(),
                      ),
                    ),
                  ),
                  _buildDarkModeSwitch(
                      context, isDark, themeService, localizations),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: localizations.logout,
                    onTap: () {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      authService.logout().then((_) {
                        Navigator.pushReplacementNamed(context, '/login');
                      });
                    },
                    textColor: theme.colorScheme.error,
                    iconColor: theme.colorScheme.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDarkModeSwitch(BuildContext context, bool isDark,
      ThemeService themeService, AppLocalizations localizations) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.dark_mode_outlined,
        color: theme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        localizations.darkMode,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (value) {
          themeService.setTheme(value ? ThemeType.night : ThemeType.day);
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
