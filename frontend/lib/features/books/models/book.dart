class Book {
  final int id;
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final bool isApproved;
  final String category;
  final String language;
  final String? description;
  final String? pdfUrl;
  final String? epubUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.isApproved,
    required this.category,
    required this.language,
    this.description,
    this.pdfUrl,
    this.epubUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      imageUrl: json['cover_url'] ?? 
                json['pdf_url'] ?? 
                'assets/images/books/default_book.png',
      rating: (json['rating'] ?? 4.5).toDouble(),
      isApproved: json['approved'] is bool 
          ? json['approved'] 
          : json['approved'] == 1,
      category: json['category'] ?? 'Uncategorized',
      language: json['language'] ?? 'Unknown',
      description: json['description'],
      pdfUrl: json['pdf_url'],
      epubUrl: json['epub_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_url': imageUrl,
      'rating': rating,
      'approved': isApproved,
      'category': category,
      'language': language,
      'description': description,
      'pdf_url': pdfUrl,
      'epub_url': epubUrl,
    };
  }
}
