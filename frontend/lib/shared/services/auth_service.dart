import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart'; // Added for ScaffoldMessenger

// For Railway production deployment:
const String backendBaseUrl = 'https://amenapp-production.up.railway.app';

// For Android emulator use:
//const String backendBaseUrl = 'http://10.0.2.2:8001';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _currentUserEmail;
  String?
      _accessToken; // Store the JWT/Sanctum token for authenticated requests
  int? _currentUserId;
  int? get currentUserId => _currentUserId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get currentUserEmail => _currentUserEmail;
  String? get accessToken => _accessToken;

  /// Authenticates user with the Laravel backend API
  /// Returns true on success, throws exception on failure
  Future<void> login(String email, String password) async {
    final url = Uri.parse('$backendBaseUrl/api/login');

    if (kDebugMode) {
      print('🔍 Attempting login to: $url');
      print('📧 Email: $email');
      print('🔑 Password: ${password.length} characters');
    }

    try {
      // Make HTTP POST request to login endpoint
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10)); // 10 second timeout

      if (kDebugMode) {
        print('📡 Response Status Code: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');
        print('📋 Response Headers: ${response.headers}');
      }

      // Parse the response
      if (response.statusCode == 200) {
        // Login successful - parse response data
        final responseData = jsonDecode(response.body);

        // Extract user data and token from response
        final user = responseData['user'];
        _currentUserId = user['id'];
        _accessToken = responseData['access_token'];
        _currentUserEmail = user['email'];

        // Determine if user is admin based on role field
        _isAdmin = user['role'] == 'admin';
        _isAuthenticated = true;

        // Notify listeners that authentication state has changed
        notifyListeners();

        if (kDebugMode) {
          print('✅ Login successful for: ${user['email']}');
          print('👤 User role: ${user['role']}');
          print('🔐 Access token: ${_accessToken?.substring(0, 20)}...');
        }
      } else {
        // Handle different HTTP error status codes
        String errorMsg = 'Login failed';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error.containsKey('message')) {
            errorMsg = error['message'];
          } else if (error is Map && error.containsKey('errors')) {
            // Handle validation errors
            errorMsg = error['errors'].toString();
          }
        } catch (_) {
          // If we can't parse the error, use a generic message
          errorMsg = 'Login failed with status: ${response.statusCode}';
        }

        if (kDebugMode) {
          print('❌ Login failed: $errorMsg');
        }
        throw errorMsg;
      }
    } on http.ClientException catch (e) {
      // Handle network connection errors
      if (kDebugMode) {
        print('🌐 Network error: ${e.message}');
      }
      throw 'Network error: ${e.message}. Please check your connection.';
    } on TimeoutException {
      // Handle request timeout
      if (kDebugMode) {
        print('⏰ Request timed out');
      }
      throw 'Request timed out. Please check your connection and try again.';
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      if (kDebugMode) {
        print('📝 JSON parsing error: ${e.message}');
      }
      throw 'Invalid response from server: ${e.message}';
    } catch (e) {
      // Handle any other unexpected errors
      if (kDebugMode) {
        print('💥 Unexpected error: ${e.toString()}');
      }
      throw 'Unexpected error: ${e.toString()}';
    }
  }

  /// Registers a new user with the Laravel backend API
  /// Returns true on success, throws exception on failure
  Future<void> register(String name, String email, String password,
      String? phone, String? campus, String? department) async {
    final url = Uri.parse('$backendBaseUrl/api/register');
    try {
      // Make HTTP POST request to registration endpoint
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': password,
              'phone': phone,
              'campus': campus,
              'department': department,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        // Registration successful - parse response data
        final responseData = jsonDecode(response.body);

        // Extract user data and token from response
        final user = responseData['user'];
        _currentUserId = user['id'];
        _accessToken = responseData['access_token'];
        _currentUserEmail = user['email'];

        // New registrations are typically not admin by default
        _isAdmin = user['role'] == 'admin';
        _isAuthenticated = true;

        // Notify listeners that authentication state has changed
        notifyListeners();

        if (kDebugMode) {
          print('Registration successful for: ${user['email']}');
        }
      } else {
        // Handle registration errors
        String errorMsg = 'Registration failed';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error.containsKey('message')) {
            errorMsg = error['message'];
          } else if (error is Map && error.containsKey('errors')) {
            errorMsg = error['errors'].toString();
          }
        } catch (_) {}
        throw errorMsg;
      }
    } on http.ClientException catch (e) {
      throw 'Network error: ${e.message}';
    } on TimeoutException {
      throw 'Request timed out. Please check your connection and try again.';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Logs out the current user and clears authentication state
  Future<void> logout() async {
    // If we have a token, make a logout request to the backend
    if (_accessToken != null) {
      try {
        final url = Uri.parse('$backendBaseUrl/api/logout');
        await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        // Even if logout request fails, we still clear local state
        if (kDebugMode) {
          print('Logout request failed: $e');
        }
      }
    }

    // Clear all authentication state
    _isAuthenticated = false;
    _isAdmin = false;
    _currentUserEmail = null;
    _accessToken = null;
    _currentUserId = null;

    // Notify listeners that authentication state has changed
    notifyListeners();

    if (kDebugMode) {
      print('User logged out successfully');
    }
  }

  /// Returns headers with authentication token for API requests
  /// Use this method when making authenticated requests to the backend
  Map<String, String> getAuthHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Fetch user profile data from the backend
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final url = Uri.parse('$backendBaseUrl/api/profile');

    try {
      final response = await http
          .get(url, headers: getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['user'];
      } else {
        throw 'Failed to fetch profile: ${response.statusCode}';
      }
    } on http.ClientException catch (e) {
      throw 'Network error: ${e.message}';
    } on TimeoutException {
      throw 'Request timed out';
    } catch (e) {
      throw 'Error fetching profile: ${e.toString()}';
    }
  }

  /// Update user profile information
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? campus,
    String? department,
  }) async {
    final url = Uri.parse('$backendBaseUrl/api/profile');

    try {
      final response = await http
          .put(
            url,
            headers: getAuthHeaders(),
            body: jsonEncode({
              if (name != null) 'name': name,
              if (phone != null) 'phone': phone,
              if (campus != null) 'campus': campus,
              if (department != null) 'department': department,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['user'];
      } else {
        throw 'Failed to update profile: ${response.statusCode}';
      }
    } on http.ClientException catch (e) {
      throw 'Network error: ${e.message}';
    } on TimeoutException {
      throw 'Request timed out';
    } catch (e) {
      throw 'Error updating profile: ${e.toString()}';
    }
  }

  /// Change user password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final url = Uri.parse('$backendBaseUrl/api/profile/change-password');

    try {
      final response = await http
          .post(
            url,
            headers: getAuthHeaders(),
            body: jsonEncode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to change password';
      }
    } on http.ClientException catch (e) {
      throw 'Network error: ${e.message}';
    } on TimeoutException {
      throw 'Request timed out';
    } catch (e) {
      throw 'Error changing password: ${e.toString()}';
    }
  }

  /// Test backend connectivity
  Future<bool> testBackendConnection() async {
    final url = Uri.parse('$backendBaseUrl/api/test-upload');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print(
            '🔍 Backend test response: ${response.statusCode} - ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Backend test failed: $e');
      }
      return false;
    }
  }

  /// Upload profile picture to the backend
  Future<String> uploadProfilePicture(File imageFile) async {
    final url = Uri.parse('$backendBaseUrl/api/profile/upload-picture');

    if (kDebugMode) {
      print('📤 Uploading profile picture to: $url');
      print('📁 File path: ${imageFile.path}');
      print('📏 File size: ${await imageFile.length()} bytes');
    }

    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.headers['Accept'] = 'application/json';

      // Add the image file
      final file = await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      );
      request.files.add(file);

      if (kDebugMode) {
        print('📤 Sending multipart request...');
      }

      // Send the request
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('📡 Upload response status: ${response.statusCode}');
        print('📄 Upload response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final imageUrl = responseData['image_url'];

        if (kDebugMode) {
          print('✅ Upload successful, image URL: $imageUrl');
        }

        return imageUrl;
      } else {
        String errorMessage = 'Failed to upload image';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        if (kDebugMode) {
          print('❌ Upload failed: $errorMessage');
        }

        throw errorMessage;
      }
    } on http.ClientException catch (e) {
      final error = 'Network error: ${e.message}';
      if (kDebugMode) {
        print('🌐 $error');
      }
      throw error;
    } on TimeoutException {
      const error = 'Upload timed out';
      if (kDebugMode) {
        print('⏰ $error');
      }
      throw error;
    } catch (e) {
      final error = 'Error uploading image: ${e.toString()}';
      if (kDebugMode) {
        print('💥 $error');
      }
      throw error;
    }
  }

  /// Update user profile picture URL
  Future<void> updateProfilePicture(String imageUrl) async {
    final url = Uri.parse('$backendBaseUrl/api/profile/update-picture');

    try {
      final response = await http
          .post(
            url,
            headers: getAuthHeaders(),
            body: jsonEncode({
              'profile_picture': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to update profile picture';
      }
    } on http.ClientException catch (e) {
      throw 'Network error: ${e.message}';
    } on TimeoutException {
      throw 'Request timed out';
    } catch (e) {
      throw 'Error updating profile picture: ${e.toString()}';
    }
  }

  /// Fetch all pending users (admin only)
  Future<List<Map<String, dynamic>>> fetchPendingUsers() async {
    final url = Uri.parse('$backendBaseUrl/api/admin/pending-users');
    final response = await http.get(url, headers: getAuthHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw 'Failed to fetch pending users: ${response.statusCode}';
    }
  }

  /// Approve a user by ID (admin only)
  Future<void> approveUser(int userId) async {
    final url = Uri.parse('$backendBaseUrl/api/admin/approve-user/$userId');
    final response = await http.post(url, headers: getAuthHeaders());
    if (response.statusCode != 200) {
      throw 'Failed to approve user: ${response.statusCode}';
    }
  }

  /// Fetch all conversations for the authenticated user (admin or user)
  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final url = Uri.parse('$backendBaseUrl/api/chat/conversations');
    final response = await http.get(url, headers: getAuthHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw 'Failed to fetch conversations: ${response.statusCode}';
    }
  }

  /// Fetch all approved users for chat (except self)
  Future<List<Map<String, dynamic>>> fetchApprovedUsers() async {
    final url = Uri.parse('$backendBaseUrl/api/chat/approved-users');
    final response = await http.get(url, headers: getAuthHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw 'Failed to fetch approved users: ${response.statusCode}';
    }
  }

  /// Fetch the saved messages (self-chat) conversation and its messages
  Future<Map<String, dynamic>> fetchSavedMessages() async {
    final url = Uri.parse('$backendBaseUrl/api/chat/saved-messages');
    final response = await http.get(url, headers: getAuthHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw 'Failed to fetch saved messages: \\${response.statusCode}';
    }
  }

  /// Checks backend connectivity at app startup
  static Future<bool> checkBackendConnection(BuildContext context) async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/test-db');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend error: ${response.statusCode}')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot connect to backend. Check IP/port.')),
      );
      return false;
    }
  }

  /// Get the full URL for a profile image
  static String? getProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null; // Use default asset image
    }
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If it starts with /storage/, construct the full URL
    if (imagePath.startsWith('/storage/')) {
      return '$backendBaseUrl$imagePath';
    }
    
    // If it starts with /, construct the full URL
    if (imagePath.startsWith('/')) {
      return '$backendBaseUrl$imagePath';
    }
    
    // If it's just a filename, assume it's in the profile-pictures directory
    if (!imagePath.contains('/')) {
      return '$backendBaseUrl/storage/profile-pictures/$imagePath';
    }
    
    // If it's a relative path, construct the full URL
    return '$backendBaseUrl/storage/$imagePath';
  }

  /// Get the appropriate ImageProvider for a profile image
  static ImageProvider getProfileImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/images/profiles/default_profile.png');
    }
    
    // Handle base64 images
    if (imagePath.startsWith('data:image/')) {
      return MemoryImage(base64Decode(imagePath.split(',')[1]));
    }
    
    final imageUrl = getProfileImageUrl(imagePath);
    
    if (imageUrl != null) {
      return NetworkImage(imageUrl);
    } else {
      return const AssetImage('assets/images/profiles/default_profile.png');
    }
  }
}
