import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  String? _userId;
  String? _username;
  String? _email;
  String? _profilePicture;

  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get profilePicture => _profilePicture;

  void setUser({
    required String userId,
    required String username,
    required String email,
    String? profilePicture,
  }) {
    _userId = userId;
    _username = username;
    _email = email;
    _profilePicture = profilePicture;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _username = null;
    _email = null;
    _profilePicture = null;
    notifyListeners();
  }

  bool get isLoggedIn => _userId != null;
}
