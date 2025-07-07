import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onChangePicture,
            child: const Text('Hello'),
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
