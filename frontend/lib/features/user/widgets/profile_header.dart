import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';

class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onChangePicture;
  final String defaultProfileImage;

  const ProfileHeader({
    Key? key,
    required this.userProfile,
    required this.onChangePicture,
    this.defaultProfileImage = 'assets/images/profiles/default_profile.png',
  }) : super(key: key);

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  @override
  Widget build(BuildContext context) {
    // Helper function to get full image URL (non-nullable)
    String _getFullImageUrl(String? imagePath) {
      if (imagePath == null || imagePath.isEmpty)
        return widget.defaultProfileImage;
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return imagePath;
      }
      if (imagePath.startsWith('/')) {
        return 'http://10.36.146.58:8000$imagePath';
      }
      return imagePath;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: widget.onChangePicture,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      widget.userProfile?['profile_picture'] != null
                          ? NetworkImage(_getFullImageUrl(
                              widget.userProfile!['profile_picture']!))
                          : AssetImage(widget.defaultProfileImage)
                              as ImageProvider<Object>,
                  onBackgroundImageError: (_, __) {},
                  child: widget.userProfile?['profile_picture'] == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 64,
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.userProfile?['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userProfile?['email'] ?? 'No Email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.userProfile?['campus'] ?? 'No Campus'} • ${widget.userProfile?['department'] ?? 'No Department'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onChangePicture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
            child: Text(
              AppLocalizations.of(context).editProfile,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
