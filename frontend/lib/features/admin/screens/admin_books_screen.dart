import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

class Book {
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final bool isApproved;
  final String category;

  Book({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    this.isApproved = false,
    this.category = 'Uncategorized',
  });
}

class AdminBooksScreen extends StatefulWidget {
  AdminBooksScreen({Key? key}) : super(key: key) {
    print('AdminBooksScreen constructor called');
  }

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _showApprovedOnly = false;

  @override
  void initState() {
    super.initState();
    print('AdminBooksScreen initState called');
  }

  final List<String> _categories = [
    'all_books',
    'pending_approval',
    'categories',
    'authors'
  ];

  final List<Book> _books = [
    Book(
      title: 'Rich Dad Poor Dad',
      author: 'Robert T. Kiyosaki',
      imageUrl: 'assets/images/books/rich_dad.jpg',
      rating: 4.5,
      isApproved: true,
      category: 'Finance',
    ),
    Book(
      title: 'The Lean Startup',
      author: 'Eric Ries',
      imageUrl: 'assets/images/books/lean_startup.jpg',
      rating: 4.7,
      isApproved: true,
      category: 'Business',
    ),
    Book(
      title: 'The 4-Hour Work Week',
      author: 'Timothy Ferriss',
      imageUrl: 'assets/images/books/4hour_week.jpg',
      rating: 4.6,
      isApproved: false,
      category: 'Productivity',
    ),
    Book(
      title: 'The Subtle Art of Not Giving a F*ck',
      author: 'Mark Manson',
      imageUrl: 'assets/images/books/subtle_art.jpg',
      rating: 4.5,
      isApproved: true,
      category: 'Self-Help',
    ),
    Book(
      title: 'The Modern Alphabet',
      author: 'Charles Duhigg',
      imageUrl: 'assets/images/books/modern_alphabet.jpg',
      rating: 4.8,
      isApproved: false,
      category: 'Psychology',
    ),
    Book(
      title: 'Think and Grow Rich',
      author: 'Napoleon Hill',
      imageUrl: 'assets/images/books/think_grow_rich.jpg',
      rating: 4.9,
      isApproved: true,
      category: 'Success',
    ),
  ];

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

    // Filter by category
    if (_selectedCategoryIndex == 1) {
      // Pending Approval
      filtered = filtered.where((book) => !book.isApproved).toList();
    } else if (_selectedCategoryIndex == 2) {
      // Categories
      // In a real app, we would show a list of categories
      // For now, we'll just return all books
    }

    // Filter by approval status if toggle is on
    if (_showApprovedOnly) {
      filtered = filtered.where((book) => book.isApproved).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                    icon: const Icon(Icons.notifications_outlined, size: 24),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover with Approval Badge
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title
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
                      // Author
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
                      // Rating and Category
                      Row(
                        children: [
                          // Rating stars
                          SizedBox(
                            width: 50,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ...List.generate(5, (index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right: index < 4 ? 0.5 : 0),
                                    child: Icon(
                                      Icons.star,
                                      size: 7,
                                      color: index < (book.rating).floor()
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
                          // Category label
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
