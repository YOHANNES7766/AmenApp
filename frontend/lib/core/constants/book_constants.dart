class BookConstants {
  // Book categories
  static const List<String> categories = [
    'Fiction',
    'Non-Fiction',
    'Religious',
    'Educational',
    'Biography',
    'History',
    'Science',
    'Technology',
    'Art',
    'Music',
    'Poetry',
    'Drama',
    'Philosophy',
    'Psychology',
    'Self-Help',
    'Health',
    'Cooking',
    'Travel',
    'Children',
    'Young Adult',
    'Romance',
    'Mystery',
    'Fantasy',
    'Horror',
    'Thriller',
  ];

  // File size limits
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxCoverSize = 5 * 1024 * 1024; // 5MB

  // Pagination
  static const int defaultPageSize = 20;

  // Search debounce delay
  static const int searchDebounceMs = 500;

  // Supported book formats
  static const List<String> supportedBookFormats = ['pdf', 'epub'];

  // Supported image formats
  static const List<String> supportedImageFormats = ['jpeg', 'png', 'jpg', 'gif'];

  // Default values
  static const String defaultCategory = 'Uncategorized';
  static const String defaultLanguage = 'Unknown';
  static const String defaultBookImage = 'assets/images/books/default_book.png';
  static const double defaultRating = 0.0;
}
