import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/auth_service.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String imageUrl; // This can be a cover image URL
  final double rating;
  final bool isApproved;
  final String category;
  final String language;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.isApproved,
    required this.category,
    required this.language,
  });
}

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  List<Book> _books = [];
  String? _selectedLanguage;
  XFile? _coverImageFile;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'Books',
    'Pending',
    'Categories',
    'Authors',
    'Languages',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePages) {
        _loadMoreBooks();
      }
    }
  }

  Future<void> _fetchBooks({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _books.clear();
        _hasMorePages = true;
      });
    }
    
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = Dio();
      
      final queryParams = {
        'page': _currentPage.toString(),
        'per_page': '20',
        if (_selectedCategoryIndex == 0) 'approved': 'true',
        if (_selectedCategoryIndex == 1) 'approved': 'false',
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
        if (_selectedLanguage != null) 'language': _selectedLanguage!,
      };
      
      final uri = Uri.parse(ApiConstants.books).replace(queryParameters: queryParams);
      
      final response = await dio.get(
        uri.toString(),
        options: Options(headers: {
          'Authorization': 'Bearer ${authService.accessToken}',
          'Accept': 'application/json',
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        final List bookData = responseData['data'] ?? [];
        final newBooks = bookData
            .map((b) => Book(
                  id: b['id'],
                  title: b['title'],
                  author: b['author'],
                  imageUrl: b['cover_url'] ??
                      b['pdf_url'] ??
                      'assets/images/books/default_book.png',
                  rating: 4.5, // Placeholder
                  isApproved: b['approved'] is bool
                      ? b['approved']
                      : b['approved'] == 1,
                  category: b['category'] ?? 'Uncategorized',
                  language: b['language'] ?? 'Unknown',
                ))
            .toList();
        
        setState(() {
          if (refresh || _currentPage == 1) {
            _books = newBooks;
          } else {
            _books.addAll(newBooks);
          }
          _hasMorePages = responseData['has_more'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching books: ${e.toString()}');
      if (refresh || _currentPage == 1) {
        setState(() {
          _books = [];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreBooks() async {
    if (!_hasMorePages || _isLoading) return;
    _currentPage++;
    await _fetchBooks();
  }

  List<String> get _allLanguages {
    final langs = _books.map((b) => b.language).toSet().toList();
    langs.sort();
    return langs;
  }

  List<Book> get filteredBooks {
    // Server-side filtering is now handled in _fetchBooks
    return _books;
  }

  void _showLanguagePicker() async {
    final langs = _allLanguages;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: langs
            .map((lang) => SimpleDialogOption(
                  child: Text(lang),
                  onPressed: () => Navigator.pop(context, lang),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedLanguage = selected;
      });
      _fetchBooks(refresh: true);
    }
  }

  void _showUploadDialog() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final categoryController = TextEditingController();
    final languageController = TextEditingController();
    XFile? coverImage;
    PlatformFile? bookFile;
    bool isUploading = false;
    String? pickedBookType; // 'pdf' or 'epub'
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Book'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(labelText: 'Author'),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: languageController,
                      decoration: const InputDecoration(labelText: 'Language'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() {
                                coverImage = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: Text(coverImage != null
                              ? 'Change Cover'
                              : 'Pick Cover'),
                        ),
                        if (coverImage != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Image.file(File(coverImage!.path),
                                width: 40, height: 40),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'epub'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final ext = file.extension?.toLowerCase();
                            setState(() {
                              bookFile = file;
                              pickedBookType = (ext == 'pdf')
                                  ? 'pdf'
                                  : (ext == 'epub' ? 'epub' : null);
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          bookFile != null
                              ? (bookFile!.name.length > 20 
                                  ? '${bookFile!.name.substring(0, 20)}...'
                                  : bookFile!.name)
                              : 'Pick PDF or EPUB',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  if (coverImage == null ||
                                      bookFile == null ||
                                      pickedBookType == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a cover image and a PDF or EPUB file.')));
                                    return;
                                  }
                                  setState(() => isUploading = true);
                                  final dio = Dio();
                                  final formData = FormData.fromMap({
                                    'title': titleController.text.trim(),
                                    'author': authorController.text.trim(),
                                    'category': categoryController.text.trim(),
                                    'language': languageController.text.trim(),
                                    if (coverImage != null)
                                      'cover': await MultipartFile.fromFile(
                                          coverImage!.path,
                                          filename: coverImage!.name),
                                    if (bookFile != null &&
                                        pickedBookType == 'pdf')
                                      'pdf': await MultipartFile.fromFile(
                                          bookFile!.path!,
                                          filename: bookFile!.name),
                                    if (bookFile != null &&
                                        pickedBookType == 'epub')
                                      'epub': await MultipartFile.fromFile(
                                          bookFile!.path!,
                                          filename: bookFile!.name),
                                  });
                                  try {
                                    final authService = Provider.of<AuthService>(context, listen: false);
                                    final response = await dio.post(
                                      ApiConstants.bookUpload,
                                      data: formData,
                                      options: Options(headers: {
                                        'Authorization': 'Bearer ${authService.accessToken}',
                                        'Accept': 'application/json'
                                      }),
                                    );
                                    if (response.statusCode == 201) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Book uploaded successfully!')));
                                      Navigator.pop(context);
                                      _fetchBooks(refresh: true);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Upload failed: \\${response.data}')));
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error: \\${e.toString()}')));
                                  }
                                  setState(() => isUploading = false);
                                },
                          child: isUploading
                              ? const CircularProgressIndicator()
                              : const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
            tooltip: 'Upload Book',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Categories
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            // Debounce search
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_searchController.text == value) {
                                _fetchBooks(refresh: true);
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                              if (index != 4) _selectedLanguage = null;
                            });
                            if (index == 4) {
                              _showLanguagePicker();
                            } else {
                              _fetchBooks(refresh: true);
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _categories[index],
                                style: TextStyle(
                                  color: _selectedCategoryIndex == index
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_selectedCategoryIndex == index)
                                Container(
                                  height: 2,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Books Grid
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredBooks.length + (_hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredBooks.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final book = filteredBooks[index];
                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigate to book detail
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: book.imageUrl.startsWith('http') ||
                                            book.imageUrl
                                                .startsWith('/storage/')
                                        ? NetworkImage(book.imageUrl)
                                            as ImageProvider
                                        : AssetImage(book.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              book.author,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...List.generate(5, (i) {
                                        return Icon(
                                          Icons.star,
                                          size: 6,
                                          color: i < (book.rating).floor()
                                              ? Colors.amber
                                              : Colors.grey[300],
                                        );
                                      }),
                                      const SizedBox(width: 2),
                                      Text(
                                        book.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      book.category,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
