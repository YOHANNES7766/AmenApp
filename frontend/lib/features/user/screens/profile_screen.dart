import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../../../shared/services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../widgets/profile_header.dart';
import 'prayer_requests_screen.dart';
import 'completed_devotions_screen.dart';
import 'saved_notes_screen.dart';
import 'settings_screens.dart';
import 'joined_events_screen.dart';
import 'notifications_screen.dart';
import 'theme_screen.dart';
import 'attendance_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({Key? key, this.isTab = true}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String defaultProfileImage =
      'assets/images/profiles/default_profile.png';

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profile = await authService.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _buildProfileBody(),
    );
  }

  Widget _buildProfileBody() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return const Center(child: Text('No profile data available'));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              userProfile: _userProfile,
              onChangePicture: _handleImageSelection,
            ),

            // Debug Section (only in debug mode)
            if (kDebugMode)
              _buildSection(
                title: 'Debug Tools',
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Test Profile Load'),
                    subtitle: const Text('Test fetching profile data'),
                    onTap: () async {
                      try {
                        final authService =
                            Provider.of<AuthService>(context, listen: false);
                        final profile = await authService.fetchUserProfile();
                        print('Current profile: $profile');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Profile loaded: ${profile['name']}')),
                        );
                      } catch (e) {
                        print('Error fetching profile: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.wifi),
                    title: const Text('Test Backend Connection'),
                    subtitle: const Text('Test backend connectivity'),
                    onTap: () async {
                      try {
                        final authService =
                            Provider.of<AuthService>(context, listen: false);
                        final isConnected =
                            await authService.testBackendConnection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isConnected
                                ? 'Backend connected!'
                                : 'Backend connection failed'),
                            backgroundColor:
                                isConnected ? Colors.green : Colors.red,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Test failed: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),

            // Profile Information Section
            _buildSection(
              title: 'Profile Information',
              children: [
                _buildInfoTile('Name',
                    _userProfile!['name']?.toString() ?? 'Not provided'),
                _buildInfoTile('Email',
                    _userProfile!['email']?.toString() ?? 'Not provided'),
                _buildInfoTile('Phone',
                    _userProfile!['phone']?.toString() ?? 'Not provided'),
                _buildInfoTile('Campus',
                    _userProfile!['campus']?.toString() ?? 'Not provided'),
                _buildInfoTile('Department',
                    _userProfile!['department']?.toString() ?? 'Not provided'),
                _buildInfoTile(
                    'Role', _userProfile!['role']?.toString() ?? 'user'),
              ],
            ),

            // Profile Menu Items
            _buildSection(
              title: AppLocalizations.of(context).spiritualJourney,
              children: [
                _buildMenuItem(
                  icon: Icons.front_hand,
                  title: AppLocalizations.of(context).myPrayers,
                  subtitle: AppLocalizations.of(context).viewTrackPrayers,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrayerRequestsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.check_circle_outline,
                  title: AppLocalizations.of(context).completedDevotions,
                  subtitle: AppLocalizations.of(context).trackDevotionProgress,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletedDevotionsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today_outlined,
                  title: AppLocalizations.of(context).attendance,
                  subtitle: AppLocalizations.of(context).trackChurchAttendance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.book_outlined,
                  title: AppLocalizations.of(context).savedNotes,
                  subtitle: AppLocalizations.of(context).accessSermonNotes,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedNotesScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.event_outlined,
                  title: AppLocalizations.of(context).joinedEvents,
                  subtitle: AppLocalizations.of(context).viewUpcomingEvents,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinedEventsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Settings Section
            _buildSection(
              title: AppLocalizations.of(context).settings,
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: AppLocalizations.of(context).notifications,
                  subtitle: AppLocalizations.of(context).notificationSettings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.palette_outlined,
                  title: AppLocalizations.of(context).theme,
                  subtitle: AppLocalizations.of(context).changeAppTheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: AppLocalizations.of(context).appSettings,
                  subtitle: AppLocalizations.of(context).appPreferences,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
      leading: Icon(
        _getIconForField(label),
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  IconData _getIconForField(String field) {
    switch (field.toLowerCase()) {
      case 'name':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'campus':
        return Icons.school;
      case 'department':
        return Icons.business;
      case 'role':
        return Icons.admin_panel_settings;
      default:
        return Icons.info;
    }
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
        color: iconColor ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: textColor?.withOpacity(0.7) ?? Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _handleImageSelection() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(AppLocalizations.of(context).takePhoto),
            onTap: () async {
              Navigator.pop(context);
              await _pickAndUploadImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(AppLocalizations.of(context).chooseFromGallery),
            onTap: () async {
              Navigator.pop(context);
              await _pickAndUploadImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final authService = Provider.of<AuthService>(context, listen: false);

          // Upload the image (this also updates the user profile automatically)
          await authService.uploadProfilePicture(File(image.path));

          // Reload the profile to get updated data
          await _loadUserProfile();

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ProfileContent extends StatelessWidget {
  final bool isTab;
  const ProfileContent({Key? key, this.isTab = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(isTab: isTab);
  }
}
