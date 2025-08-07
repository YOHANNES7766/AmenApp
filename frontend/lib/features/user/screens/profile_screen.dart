import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Added for File
import '../../../shared/services/auth_service.dart' as auth;
import '../../../core/localization/app_localizations.dart';
import 'prayer_requests_screen.dart';
import 'completed_devotions_screen.dart';
import 'saved_notes_screen.dart';
import 'settings_screens.dart';
import 'joined_events_screen.dart';
import 'notifications_screen.dart';
import 'theme_screen.dart';
import 'attendance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding



class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({Key? key, this.isTab = true}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _error;
  bool _imageLoadError = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _saveProfileToCache(Map<String, dynamic> profile) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('cached_user_profile', jsonEncode(profile));
}

Future<Map<String, dynamic>?> _loadProfileFromCache() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('cached_user_profile');
  if (cachedData != null) {
    return jsonDecode(cachedData);
  }
  return null;
}

Future<void> _loadUserProfile() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  // Step 1: Load from cache first
  final cachedProfile = await _loadProfileFromCache();
  if (cachedProfile != null && mounted) {
    setState(() {
      _userProfile = cachedProfile;
      _isLoading = false;
    });
  }

  // Step 2: Fetch from network and update cache
  try {
    final authService = Provider.of<auth.AuthService>(context, listen: false);
    final profile = await authService.fetchUserProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _isLoading = false;
      _error = null;
      _imageLoadError = false;
    });

    await _saveProfileToCache(profile); // Save to cache
  } catch (e, stackTrace) {
    if (!mounted) return;
    debugPrint('Profile loading error: $e');
    debugPrint('Stack trace: $stackTrace');
    setState(() {
      _error = 'Failed to load profile: ${e.toString()}';
      _isLoading = false;
    });
  }
}

  Future<void> _handleImageSelection() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Lower quality for smaller size
        maxWidth: 300,    // Smaller width for profile
      );

      if (pickedFile != null) {
        final authService =
            Provider.of<auth.AuthService>(context, listen: false);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Upload the profile picture (this also updates the user profile automatically)
          await authService.uploadProfilePicture(File(pickedFile.path));
          
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
      debugPrint('Error selecting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: AppLocalizations.of(context).refresh,
          ),
        ],
      ),
      body: _buildProfileBody(),
    );
  }

  Widget _buildProfileBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).refresh),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_userProfile == null) {
      return const Center(
        child: Text(
          'No profile data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image and Name
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildProfileImage(_userProfile!['profile_picture']),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _handleImageSelection,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile!['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userProfile!['email'] ?? 'No Email',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Profile Information Section (Card)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                      'Name', _userProfile!['name'] ?? 'Not provided'),
                  _buildInfoTile(
                      'Email', _userProfile!['email'] ?? 'Not provided'),
                  _buildInfoTile(
                      'Phone', _userProfile!['phone'] ?? 'Not provided'),
                  _buildInfoTile(
                      'Campus', _userProfile!['campus'] ?? 'Not provided'),
                  _buildInfoTile('Department',
                      _userProfile!['department'] ?? 'Not provided'),
                  _buildInfoTile('Role', _userProfile!['role'] ?? 'user'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Spiritual Journey Section (Card)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).spiritualJourney,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    subtitle:
                        AppLocalizations.of(context).trackDevotionProgress,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CompletedDevotionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: AppLocalizations.of(context).attendance,
                    subtitle:
                        AppLocalizations.of(context).trackChurchAttendance,
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
            ),
          ),
          const SizedBox(height: 16),

          // Settings Section (Card)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).settings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
            ),
          ),
          const SizedBox(height: 16),

          // Logout Section (Card)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMenuItem(
                icon: Icons.logout,
                title: AppLocalizations.of(context).logout,
                subtitle: AppLocalizations.of(context).signOut,
                onTap: () {
                  final authService =
                      Provider.of<auth.AuthService>(context, listen: false);
                  authService.logout().then((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  });
                },
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imagePath) {
  final imageProvider = auth.AuthService.getProfileImageProvider(imagePath);
  final hasImage = imageProvider != null && !_imageLoadError;

  debugPrint('Building profile image:');
  debugPrint('  Original path: $imagePath');
  debugPrint('  Using imageProvider: ${imageProvider.runtimeType}');
  debugPrint('  Has image: $hasImage');
  debugPrint('  Image load error: $_imageLoadError');

  return CircleAvatar(
    radius: 48,
    backgroundColor: Colors.grey[200],
    backgroundImage: hasImage ? imageProvider : null,
    onBackgroundImageError: hasImage
        ? (exception, stackTrace) {
            debugPrint('Failed to load profile image: $exception');
            setState(() {
              _imageLoadError = true;
            });
          }
        : null,
    child: !hasImage
        ? const Icon(
            Icons.person,
            size: 48,
            color: Colors.grey,
          )
        : null,
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
                color: textColor?.withValues(alpha: 0.7) ?? Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
