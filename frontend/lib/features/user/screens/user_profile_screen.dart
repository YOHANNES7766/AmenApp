import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/images/profiles/default_profile.png';
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    if (imagePath.startsWith('/')) {
      return 'http://10.36.146.58:8000$imagePath';
    }
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] ?? 'User Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    NetworkImage(_getFullImageUrl(user['profile_picture'])),
                child: user['profile_picture'] == null ||
                        user['profile_picture'].isEmpty
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user['name'] ?? 'No Name',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user['email'] ?? 'No Email',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                '${user['campus'] ?? 'No Campus'} • ${user['department'] ?? 'No Department'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
