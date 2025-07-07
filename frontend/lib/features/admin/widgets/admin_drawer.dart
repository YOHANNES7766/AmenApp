import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/theme_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../screens/attendance_management.dart';
import '../screens/language_management.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final localizations = AppLocalizations.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.adminDashboard,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.manageEfficiently,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: localizations.userManagement,
                    index: 1,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_today,
                    title: localizations.attendanceList,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceManagement(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.book,
                    title: localizations.contentManagement,
                    index: 3,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.library_books,
                    title: localizations.books,
                    onTap: () {
                      print('Books menu item clicked in drawer');
                      onItemSelected(11);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat,
                    title: localizations.chat,
                    index: 10,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.event,
                    title: localizations.eventManagement,
                    index: 4,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_pin_circle,
                    title: localizations.prayerModeration,
                    index: 5,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.comment,
                    title: localizations.commentaryModeration,
                    index: 6,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications,
                    title: localizations.notificationControl,
                    index: 7,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.feedback,
                    title: localizations.feedbackManagement,
                    index: 8,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: localizations.appSettings,
                    index: 9,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics,
                    title: localizations.analyticsDashboard,
                    index: 10,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.language,
                    title: localizations.languages,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageManagement(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDarkModeSwitch(context, isDark, themeService),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: localizations.signOut,
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
    int? index,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isSelected = index != null && index == selectedIndex;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ??
            (isSelected ? theme.primaryColor : theme.iconTheme.color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ??
              (isSelected
                  ? theme.primaryColor
                  : theme.textTheme.bodyLarge?.color),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
      ),
      selected: isSelected,
      onTap: () {
        if (index != null) {
          onItemSelected(index);
          Navigator.pop(context);
        } else if (onTap != null) {
          onTap();
        }
      },
    );
  }

  Widget _buildDarkModeSwitch(
    BuildContext context,
    bool isDark,
    ThemeService themeService,
  ) {
    final localizations = AppLocalizations.of(context);
    return SwitchListTile(
      title: Text(localizations.darkMode),
      value: isDark,
      onChanged: (value) {
        themeService.setTheme(
          value ? ThemeType.night : ThemeType.day,
        );
      },
    );
  }
}
