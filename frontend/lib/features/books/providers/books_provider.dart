import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/book_constants.dart';
import '../../../shared/services/auth_service.dart';
import '../models/book.dart';

class BooksProvider extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;
  bool _hasMorePages = true;
  int _currentPage = 1;
  String? _selectedLanguage;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  String? _error;
  Timer? _searchTimer;

  // Getters
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;
  String? get selectedLanguage => _selectedLanguage;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  bool get hasError => _error != null;
  String? get errorMessage => _error;

  List<String> get allLanguages {
    final langs = _books.map((b) => b.language).toSet().toList();
    langs.sort();
    return langs;
  }

  void setSelectedCategoryIndex(int index) {
    if (_selectedCategoryIndex != index) {
      _selectedCategoryIndex = index;
      if (index != 4) _selectedLanguage = null;
      _resetAndFetch();
    }
  }

  void setSelectedLanguage(String? language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      _resetAndFetch();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: BookConstants.searchDebounceMs), () {
      _resetAndFetch();
    });
  }

  void updateSearchQuery(String query) {
    setSearchQuery(query);
  }

  void updateFilters({bool? approved, String? language}) {
    bool shouldRefresh = false;
    
    if (language != _selectedLanguage) {
      _selectedLanguage = language;
      shouldRefresh = true;
    }
    
    // Update category index based on approved filter
    int newCategoryIndex = _selectedCategoryIndex;
    if (approved == true && _selectedCategoryIndex != 0) {
      newCategoryIndex = 0; // Books (approved)
      shouldRefresh = true;
    } else if (approved == false && _selectedCategoryIndex != 1) {
      newCategoryIndex = 1; // Pending
      shouldRefresh = true;
    }
    
    if (newCategoryIndex != _selectedCategoryIndex) {
      _selectedCategoryIndex = newCategoryIndex;
    }
    
    if (shouldRefresh) {
      _resetAndFetch();
    }
  }

  void _resetAndFetch({BuildContext? context}) {
    _currentPage = 1;
    _books.clear();
    _hasMorePages = true;
    _error = null;
    notifyListeners(); // Notify UI immediately to show loading state
    fetchBooks(context: context);
  }

  Future<void> fetchBooks({bool refresh = false, BuildContext? context}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _books.clear();
      _hasMorePages = true;
      _error = null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      ));
      
      final queryParams = {
        'page': _currentPage.toString(),
        'per_page': BookConstants.defaultPageSize.toString(),
        if (_selectedCategoryIndex == 0) 'approved': 'true',
        if (_selectedCategoryIndex == 1) 'approved': 'false',
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedLanguage != null) 'language': _selectedLanguage!,
      };

      // Get auth token from AuthService if context is available
      String? authToken;
      if (context != null) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          authToken = authService.accessToken;
        } catch (e) {
          // AuthService not available, proceed without token
        }
      }

      final uri = Uri.parse(ApiConstants.books).replace(queryParameters: queryParams);
      final response = await dio.get(
        uri.toString(),
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List bookData = responseData['data'] ?? [];
        final newBooks = bookData.map((b) => Book.fromJson(b)).toList();

        if (refresh || _currentPage == 1) {
          _books = newBooks;
        } else {
          _books.addAll(newBooks);
        }
        
        _hasMorePages = responseData['has_more'] ?? false;
        _error = null;
      }
    } catch (e) {
      String errorMessage = 'Failed to load books';
      
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout. Please check your internet connection and try again.';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Server response timeout. Please try again.';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'Request timeout. Please try again.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Unable to connect to server. Please check your internet connection.';
            break;
          case DioExceptionType.badResponse:
            final statusCode = e.response?.statusCode;
            if (statusCode == 401) {
              errorMessage = 'Authentication required. Please log in to view books.';
            } else if (statusCode == 403) {
              errorMessage = 'Access denied. You don\'t have permission to view books.';
            } else if (statusCode == 404) {
              errorMessage = 'Books service not found. Please try again later.';
            } else if (statusCode == 500) {
              errorMessage = 'Server error. Please try again later.';
            } else {
              errorMessage = 'Server error ($statusCode). Please try again later.';
            }
            break;
          default:
            errorMessage = 'Network error. Please try again.';
        }
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      
      _error = errorMessage;
      if (refresh || _currentPage == 1) {
        _books = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreBooks() async {
    if (!_hasMorePages || _isLoading) return;
    _currentPage++;
    await fetchBooks();
  }

  Future<bool> uploadBook({
    required String title,
    required String author,
    required String category,
    required String language,
    String? description,
    File? coverImage,
    File? bookFile,
    String? bookType,
    Function(double)? onProgress,
    BuildContext? context,
  }) async {
    try {
      // Validation
      if (title.trim().isEmpty || author.trim().isEmpty) {
        throw Exception('Title and author are required');
      }

      if (bookFile == null) {
        throw Exception('Please select a book file');
      }

      if (coverImage == null) {
        throw Exception('Please select a cover image');
      }

      // File size validation
      if (bookFile.lengthSync() > BookConstants.maxFileSize) {
        throw Exception('Book file size must be less than 50MB');
      }

      if (coverImage.lengthSync() > BookConstants.maxCoverSize) {
        throw Exception('Cover image size must be less than 5MB');
      }

      final dio = Dio(BaseOptions(
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      ));

      // Get auth token from AuthService if context is available
      String? authToken;
      if (context != null) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          authToken = authService.accessToken;
        } catch (e) {
          // AuthService not available, proceed without token
        }
      }

      final formData = FormData.fromMap({
        'title': title.trim(),
        'author': author.trim(),
        'category': category.trim(),
        'language': language.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        'cover': await MultipartFile.fromFile(
          coverImage.path,
          filename: coverImage.path.split('/').last,
        ),
        if (bookType == 'pdf')
          'pdf': await MultipartFile.fromFile(
            bookFile.path,
            filename: bookFile.path.split('/').last,
          ),
        if (bookType == 'epub')
          'epub': await MultipartFile.fromFile(
            bookFile.path,
            filename: bookFile.path.split('/').last,
          ),
      });

      final response = await dio.post(
        ApiConstants.bookUpload,
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        }),
        onSendProgress: onProgress != null 
            ? (sent, total) => onProgress(sent / total) 
            : null,
      );

      if (response.statusCode == 201) {
        _resetAndFetch(context: context); // Refresh the books list with context
        return true;
      }
      
      return false;
    } catch (e) {
      String errorMessage = 'Upload failed';
      
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Upload timeout. Please check your connection and try again.';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Server response timeout during upload. Please try again.';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'Upload timeout. File may be too large or connection is slow.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Unable to connect to server. Please check your internet connection.';
            break;
          case DioExceptionType.badResponse:
            final statusCode = e.response?.statusCode;
            if (statusCode == 401) {
              errorMessage = 'Authentication required. Please log in to upload books.';
            } else if (statusCode == 403) {
              errorMessage = 'Access denied. You don\'t have permission to upload books.';
            } else if (statusCode == 422) {
              errorMessage = 'Invalid file or data. Please check your inputs and try again.';
            } else if (statusCode == 413) {
              errorMessage = 'File too large. Please select a smaller file.';
            } else {
              errorMessage = 'Server error ($statusCode) during upload.';
            }
            break;
          default:
            errorMessage = 'Network error during upload. Please try again.';
        }
      } else {
        errorMessage = 'Upload failed: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}

