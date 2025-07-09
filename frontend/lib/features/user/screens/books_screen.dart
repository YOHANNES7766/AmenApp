import 'package:flutter/material.dart';
import '../../admin/screens/admin_books_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the same widget as admin for unified experience
    return AdminBooksScreen();
  }
}
