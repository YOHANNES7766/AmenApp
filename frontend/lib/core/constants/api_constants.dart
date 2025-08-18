class ApiConstants {
  // Update this to your actual backend URL
  static const String baseUrl = 'http://localhost:8000'; // Change to your Laravel backend URL
  
  // API endpoints
  static const String booksEndpoint = '/api/books';
  static const String bookUploadEndpoint = '/api/books/upload';
  static const String bookCommentsEndpoint = '/api/book-comments';
  static const String bookNotesEndpoint = '/api/book-notes';
  static const String chatEndpoint = '/api/chat';
  
  // Helper methods
  static String get books => '$baseUrl$booksEndpoint';
  static String get bookUpload => '$baseUrl$bookUploadEndpoint';
  static String get bookComments => '$baseUrl$bookCommentsEndpoint';
  static String get bookNotes => '$baseUrl$bookNotesEndpoint';
  static String get chat => '$baseUrl$chatEndpoint';
}
