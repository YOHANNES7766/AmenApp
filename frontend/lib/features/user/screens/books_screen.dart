import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../books/providers/books_provider.dart';
import '../../books/widgets/book_card.dart';
import '../../books/widgets/upload_dialog.dart';
import '../../books/screens/book_detail_screen.dart';
import '../../books/models/book.dart';
import '../../../core/constants/book_constants.dart';
import '../../../core/constants/api_constants.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryIndex = 0;
  String? _selectedLanguage;
  Timer? _searchTimer;

  final List<String> _categories = [
    'All Books',
    'Pending',
    'Categories',
    'Authors',
    'Languages',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      // Fetch all books initially (both approved and pending)
      booksProvider.fetchBooks(context: context);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      if (!booksProvider.isLoading && booksProvider.hasMorePages) {
        booksProvider.loadMoreBooks();
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: BookConstants.searchDebounceMs), () {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      booksProvider.updateSearchQuery(value);
    });
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      if (index != 4) _selectedLanguage = null;
    });
    
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    
    if (index == 4) {
      _showLanguagePicker();
    } else {
      // Update filters based on category
      bool? approved;
      if (index == 0) approved = true;  // All Books (approved only)
      if (index == 1) approved = false; // Pending only
      
      booksProvider.updateFilters(
        approved: approved,
        language: _selectedLanguage,
      );
    }
  }

  List<String> get _allLanguages {
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    final langs = booksProvider.books.map((b) => b.language).toSet().toList();
    langs.sort();
    return langs;
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
      
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      booksProvider.updateFilters(
        approved: _selectedCategoryIndex == 0 ? true : (_selectedCategoryIndex == 1 ? false : null),
        language: selected,
      );
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => const UploadDialog(),
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
      body: Consumer<BooksProvider>(
        builder: (context, booksProvider, child) {
          if (booksProvider.isLoading && booksProvider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (booksProvider.hasError && booksProvider.books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Problem',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      booksProvider.errorMessage ?? 'Unable to connect to server',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => booksProvider.fetchBooks(refresh: true, context: context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // Show debug info
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Debug Info'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Server URL: ${ApiConstants.baseUrl}'),
                                const SizedBox(height: 8),
                                Text('Error: ${booksProvider.errorMessage}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Debug Info',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => booksProvider.fetchBooks(context: context),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Category Tabs
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
                          onTap: () => _onCategoryChanged(index),
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
                  child: booksProvider.books.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.library_books,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No books found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: booksProvider.books.length + (booksProvider.hasMorePages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= booksProvider.books.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final book = booksProvider.books[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailScreen(book: book),
                                  ),
                                );
                              },
                              child: BookCard(book: book),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
