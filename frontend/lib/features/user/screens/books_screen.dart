import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoading = true);
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
        });
      }
    } catch (e) {
      debugPrint('Error fetching books: \\${e.toString()}');
      setState(() {
        _books = [];
      });
    }
    setState(() => _isLoading = false);
  }

  List<String> get _allLanguages {
    final langs = _books.map((b) => b.language).toSet().toList();
    langs.sort();
    return langs;
  }

  List<Book> get filteredBooks {
    final query = _searchController.text.toLowerCase();
    List<Book> filtered = _books;
    if (query.isNotEmpty) {
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    }
    // Tab filtering
    if (_selectedCategoryIndex == 0) {
      // All Books: only approved
      filtered = filtered.where((b) => b.isApproved).toList();
    } else if (_selectedCategoryIndex == 1) {
      // Pending: only not approved
      filtered = filtered.where((b) => !b.isApproved).toList();
    } else if (_selectedCategoryIndex == 2) {
      // Categories: could add category filter UI here
    } else if (_selectedCategoryIndex == 3) {
      // Authors: could add author filter UI here
    } else if (_selectedCategoryIndex == 4) {
      // Languages: filter by selected language
      if (_selectedLanguage != null) {
        filtered =
            filtered.where((b) => b.language == _selectedLanguage).toList();
      }
    }
    return filtered;
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
                    Row(
                      children: [
                        ElevatedButton.icon(
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
                          label: Text(bookFile != null
                              ? bookFile!.name
                              : 'Pick PDF or EPUB'),
                        ),
                      ],
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
                                    final response = await dio.post(
                                      'https://your-production-domain.com/api/books/upload',
                                      data: formData,
                                      options: Options(headers: {
                                        'Accept': 'application/json'
                                      }),
                                    );
                                    if (response.statusCode == 201) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Book uploaded successfully!')));
                                      Navigator.pop(context);
                                      _fetchBooks();
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
                          onChanged: (value) => setState(() {}),
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
                              if (index == 4) _showLanguagePicker();
                            });
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
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
                                SizedBox(
                                  width: 50,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ...List.generate(5, (i) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              right: i < 4 ? 0.5 : 0),
                                          child: Icon(
                                            Icons.star,
                                            size: 7,
                                            color: i < (book.rating).floor()
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
                                      borderRadius: BorderRadius.circular(4),
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
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
