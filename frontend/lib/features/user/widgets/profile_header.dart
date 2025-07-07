import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/auth_service.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onChangePicture;
  final String defaultProfileImage;

  const ProfileHeader({
    Key? key,
    required this.userProfile,
    required this.onChangePicture,
    this.defaultProfileImage = 'assets/images/profiles/default_profile.png',
  }) : super(key: key);

  String? _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If it's a relative path, prepend the backend URL
    if (imagePath.startsWith('/')) {
      return 'http://10.217.242.58:8000$imagePath';
    }

    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _getFullImageUrl(userProfile?['profile_picture']);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onChangePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
                  child: fullImageUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 48,
                        )
                      : null,
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
            userProfile?['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userProfile?['email'] ?? 'No Email',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
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
            child: Text(AppLocalizations.of(context).editProfile),
          ),
        ],
      ),
    );
  }
}
