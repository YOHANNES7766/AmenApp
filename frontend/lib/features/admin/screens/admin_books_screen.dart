import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../shared/services/local_db_helper.dart';
import '../../user/screens/book_detail_screen.dart';
import 'package:file_picker/file_picker.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final bool isApproved;
  final String category;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    this.isApproved = false,
    this.category = 'Uncategorized',
  });
}

class AdminBooksScreen extends StatefulWidget {
  final List<Book>? books;
  AdminBooksScreen({Key? key, this.books}) : super(key: key) {
    debugPrint('AdminBooksScreen constructor called');
  }

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _showApprovedOnly = false;
  final Map<String, double> _downloadProgress = {};
  Set<String> _downloadedBookIds = {};
  Map<String, String> _localBookPaths = {};
  final bool _showMyLibrary = false;
  List<Book> _books = [];
  bool _isLoadingBooks = false;
  List<Book> get filteredBooks {
    final query = _searchController.text.toLowerCase();
    List<Book> filtered = _books;
    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    }
    // Pending Approval section: treat both approved: 0 and approved: false as pending
    if (_selectedCategoryIndex == 1) {
      filtered = filtered.where((book) => book.isApproved == false).toList();
    } else if (_selectedCategoryIndex == 2) {
      // Categories (show all for now)
    }
    if (_showApprovedOnly) {
      filtered = filtered.where((book) => book.isApproved == true).toList();
    }
    return filtered;
  }

  // Upload book fields
  final TextEditingController _uploadTitleController = TextEditingController();
  final TextEditingController _uploadAuthorController = TextEditingController();
  final TextEditingController _uploadCategoryController =
      TextEditingController();
  final TextEditingController _uploadLanguageController =
      TextEditingController();
  final TextEditingController _uploadDescriptionController =
      TextEditingController();
  PlatformFile? _pdfFile;
  PlatformFile? _epubFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AdminBooksScreen initState called');
    if (widget.books != null) {
      _books = widget.books!;
      _isLoadingBooks = false;
    } else {
      _fetchBooks();
    }
    _loadOfflineBooks();
  }

  @override
  void dispose() {
    _uploadTitleController.dispose();
    _uploadAuthorController.dispose();
    _uploadCategoryController.dispose();
    _uploadLanguageController.dispose();
    _uploadDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOfflineBooks() async {
    final dbHelper = LocalDbHelper();
    final downloaded = await dbHelper.getDownloadedBooks();
    setState(() {
      _downloadedBookIds =
          downloaded.map((b) => b['book_id'] as String).toSet();
      _localBookPaths = {
        for (var b in downloaded)
          b['book_id'] as String: b['file_path'] as String
      };
    });
  }

  final List<String> _categories = [
    'all_books',
    'pending_approval',
    'categories',
    'Authors',
    'Languages',
  ];

  Future<void> _fetchBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      final dio = Dio();
      final response =
          await dio.get('https://your-production-domain.com/api/books');
      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          _books = data
              .map((b) => Book(
                    id: b['id'],
                    title: b['title'],
                    author: b['author'],
                    imageUrl:
                        b['pdf_url'] ?? 'assets/images/books/default_book.png',
                    rating: 4.5, // Placeholder, update as needed
                    isApproved: b['approved'] is bool
                        ? b['approved']
                        : b['approved'] == 1,
                    category: b['category'] ?? 'Uncategorized',
                  ))
              .toList();
        });
        debugPrint(
            'Fetched books: ${_books.map((b) => '[id: ${b.id}, title: ${b.title}, approved: ${b.isApproved}]').join(', ')}');
      }
    } catch (e) {
      debugPrint('Error fetching books: \\${e.toString()}');
    }
    setState(() => _isLoadingBooks = false);
  }

  Future<void> _approveBook(int bookId) async {
    try {
      final dio = Dio();
      final response = await dio.patch(
          'https://your-production-domain.com/api/books/$bookId/approve');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book approved!')),
        );
        await _fetchBooks(); // Always refresh after approval
      }
    } catch (e) {
      debugPrint('Error approving book: \\${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving book: \\${e.toString()}')),
        );
      }
    }
  }

  Future<void> _downloadBook(Book book, String format) async {
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${book.title}_${book.author}.$format';
    final filePath = '${dir.path}/$fileName';
    final url = format == 'pdf'
        ? book.imageUrl
        : null; // Replace with book.pdfUrl/epubUrl from backend
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download URL not available.')),
        );
      }
      return;
    }
    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[book.id.toString()] = received / total;
            });
          }
        },
      );
      setState(() {
        _downloadedBookIds.add(book.id.toString());
        _localBookPaths[book.id.toString()] = filePath;
        _downloadProgress.remove(book.id.toString());
      });
      // Save to sqflite for offline access
      final dbHelper = LocalDbHelper();
      await dbHelper.insertBook({
        'book_id': book.id.toString(), // Use a unique id if available
        'title': book.title,
        'author': book.author,
        'file_path': filePath,
        'format': format,
      });
    } catch (e) {
      setState(() {
        _downloadProgress.remove(book.id.toString());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: \\${e.toString()}')),
        );
      }
    }
  }

  void _openBook(Book book, String format) {
    final filePath = _localBookPaths[book.id.toString()];
    if (filePath != null && File(filePath).existsSync()) {
      OpenFile.open(filePath);
    }
  }

  Future<void> _pickFile(String type) async {
    FileType fileType = FileType.any;
    List<String>? allowedExtensions;
    if (type == 'pdf' || type == 'epub') {
      fileType = FileType.custom;
      allowedExtensions = [type];
    }
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (type == 'pdf') {
          _pdfFile = result.files.first;
        } else if (type == 'epub') {
          _epubFile = result.files.first;
        }
      });
      debugPrint(
          'Picked file: \\${result.files.first.name} (\\${result.files.first.path})');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
      }
    }
  }

  Future<void> _uploadBook() async {
    setState(() => _isUploading = true);
    try {
      if (_pdfFile == null && _epubFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF or EPUB file.')),
        );
        setState(() => _isUploading = false);
        return;
      }
      final dio = Dio();
      final formData = FormData.fromMap({
        'title': _uploadTitleController.text.trim(),
        'author': _uploadAuthorController.text.trim(),
        'category': _uploadCategoryController.text.trim(),
        'language': _uploadLanguageController.text.trim(),
        'description': _uploadDescriptionController.text.trim(),
        if (_pdfFile != null)
          'pdf': await MultipartFile.fromFile(_pdfFile!.path!,
              filename: _pdfFile!.name),
        if (_epubFile != null)
          'epub': await MultipartFile.fromFile(_epubFile!.path!,
              filename: _epubFile!.name),
        // If admin, set approved true
        if (_isAdminUser()) 'approved': true,
      });
      final response = await dio.post(
        'https://your-production-domain.com/api/books/upload',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book uploaded successfully!')));
        _uploadTitleController.clear();
        _uploadAuthorController.clear();
        _uploadCategoryController.clear();
        _uploadLanguageController.clear();
        _uploadDescriptionController.clear();
        setState(() {
          _pdfFile = null;
          _epubFile = null;
        });
        await _fetchBooks(); // Always refresh after upload
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: \\${response.data}')));
        }
      }
    } catch (e) {
      debugPrint('Upload error: \\${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: \\${e.toString()}')));
      }
    }
    setState(() => _isUploading = false);
  }

  bool _isAdminUser() {
    // TODO: Replace with your actual admin check logic (e.g., from provider or auth service)
    // For now, always return true for demonstration
    return true;
  }

  void _showUploadDialog() {
    debugPrint('Upload dialog opened');
    showDialog(
      context: context,
      builder: (context) {
        debugPrint('Upload dialog builder called');
        return AlertDialog(
          title: const Text('Upload Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _uploadTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _uploadAuthorController,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
                TextField(
                  controller: _uploadCategoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: _uploadLanguageController,
                  decoration: const InputDecoration(labelText: 'Language'),
                ),
                TextField(
                  controller: _uploadDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickFile('pdf'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(
                            _pdfFile != null ? _pdfFile!.name : 'Pick PDF'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _pickFile('epub'),
                        icon: const Icon(Icons.book),
                        label: Text(
                            _epubFile != null ? _epubFile!.name : 'Pick EPUB'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      final prevUploading = _isUploading;
                      await _uploadBook();
                      // Only close dialog if upload was successful
                      if (mounted &&
                          !prevUploading &&
                          !_isUploading &&
                          _pdfFile == null &&
                          _epubFile == null) {
                        Navigator.pop(context);
                      }
                    },
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _declineBook(int bookId) async {
    try {
      final dio = Dio();
      final response = await dio
          .delete('https://your-production-domain.com/api/books/$bookId');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book declined and deleted!')),
          );
        }
        await _fetchBooks();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to decline book: \\${response.data}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error declining book: \\${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining book: \\${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoadingBooks
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Search and Icons Row
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: localizations.search,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.library_books, size: 24),
                          onPressed: () {
                            // Show category management
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              size: 24),
                          onPressed: () {
                            // Show notifications
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Categories
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        String categoryText;
                        switch (_categories[index]) {
                          case 'all_books':
                            categoryText = localizations.books;
                            break;
                          case 'pending_approval':
                            categoryText = localizations.pending;
                            break;
                          case 'categories':
                            categoryText = localizations.categories;
                            break;
                          case 'authors':
                            categoryText = localizations.authors;
                            break;
                          default:
                            categoryText = _categories[index];
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategoryIndex = index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  categoryText,
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

                  // Approval Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Text(
                          localizations.showApprovedOnly,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Switch(
                          value: _showApprovedOnly,
                          onChanged: (value) {
                            setState(() {
                              _showApprovedOnly = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Promotional Banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.bookManagement,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizations.manageBooks,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            localizations.addNew,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Books Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: (_showMyLibrary
                              ? _books
                                  .where((b) => _downloadedBookIds
                                      .contains(b.id.toString()))
                                  .toList()
                              : filteredBooks)
                          .length,
                      itemBuilder: (context, index) {
                        final book = _showMyLibrary
                            ? _books
                                .where((b) => _downloadedBookIds
                                    .contains(b.id.toString()))
                                .toList()[index]
                            : filteredBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(
                                  title: book.title,
                                  author: book.author,
                                  imageUrl: book.imageUrl,
                                  category: book.category,
                                  rating: book.rating,
                                  bookId: book.id,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: AssetImage(book.imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (!book.isApproved)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                localizations.pending,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (!book.isApproved)
                                          Positioned(
                                            bottom: 4,
                                            left: 4,
                                            child: Row(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _approveBook(book.id),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    minimumSize:
                                                        const Size(40, 24),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: const Text('Approve',
                                                      style: TextStyle(
                                                          fontSize: 10)),
                                                ),
                                                const SizedBox(width: 4),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _declineBook(book.id),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    minimumSize:
                                                        const Size(40, 24),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: const Text('Decline',
                                                      style: TextStyle(
                                                          fontSize: 10)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (book.isApproved)
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: IconButton(
                                              icon: Icon(
                                                _downloadedBookIds.contains(
                                                        book.id.toString())
                                                    ? Icons.open_in_new
                                                    : Icons.download,
                                                color:
                                                    _downloadedBookIds.contains(
                                                            book.id.toString())
                                                        ? Colors.blue
                                                        : Colors.grey,
                                              ),
                                              onPressed: _downloadedBookIds
                                                      .contains(
                                                          book.id.toString())
                                                  ? () => _openBook(book, 'pdf')
                                                  : () => _downloadBook(
                                                      book, 'pdf'),
                                            ),
                                          ),
                                        if (_downloadedBookIds
                                            .contains(book.id.toString()))
                                          const Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Icon(Icons.check_circle,
                                                color: Colors.green, size: 18),
                                          ),
                                        if (_downloadProgress
                                            .containsKey(book.id.toString()))
                                          Positioned.fill(
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                  value: _downloadProgress[
                                                      book.id.toString()]),
                                            ),
                                          ),
                                      ],
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
                                      SizedBox(
                                        width: 50,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            ...List.generate(5, (index) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                    right: index < 4 ? 0.5 : 0),
                                                child: Icon(
                                                  Icons.star,
                                                  size: 7,
                                                  color: index <
                                                          (book.rating).floor()
                                                      ? Colors.amber
                                                      : Colors.grey[300],
                                                ),
                                              );
                                            }),
                                            const SizedBox(width: 1),
                                            Text(
                                              book.rating.toString(),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 7,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            book.category,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        tooltip: 'Upload Book',
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
