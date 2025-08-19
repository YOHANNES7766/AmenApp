import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Environment-aware base URL
  static String get baseUrl {
    // Always use Railway production URL
    return 'https://amenapp-production.up.railway.app';
    
    // Uncomment below for local development
    /*
    if (kReleaseMode) {
      // Production URL for release builds
      return 'https://amenapp-production.up.railway.app';
    } else if (Platform.isAndroid) {
      // Android emulator localhost
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator localhost
      return 'http://localhost:8000';
    } else {
      // Default fallback
      return 'http://localhost:8000';
    }
    */
  }
  
  // API endpoints
  static const String booksEndpoint = '/api/books';
  static const String bookUploadEndpoint = '/api/books/upload';
  static const String bookCommentsEndpoint = '/api/book-comments';
  static const String bookNotesEndpoint = '/api/book-notes';
  static const String chatEndpoint = '/api/chat';
  
  // Network timeouts (in milliseconds)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 60000;    // 60 seconds for uploads
  
  // Helper methods
  static String get books => '$baseUrl$booksEndpoint';
  static String get bookUpload => '$baseUrl$bookUploadEndpoint';
  static String get bookComments => '$baseUrl$bookCommentsEndpoint';
  static String get bookNotes => '$baseUrl$bookNotesEndpoint';
  static String get chat => '$baseUrl$chatEndpoint';
}
