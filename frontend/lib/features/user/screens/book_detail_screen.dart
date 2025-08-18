import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';

import '../../../core/constants/api_constants.dart';

class BookDetailScreen extends StatefulWidget {
  final String title;
  final String author;
  final String imageUrl;
  final String category;
  final double rating;
  final int? bookId;
  const BookDetailScreen({
    Key? key,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.category,
    required this.rating,
    this.bookId,
  }) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadNote();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse(
          '${ApiConstants.bookComments}?book_id=${widget.bookId}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _comments = data
              .map((c) => {
                    'author': c['user']?['name'] ?? 'User',
                    'content': c['content'],
                    'createdAt': DateTime.parse(c['created_at']),
                  })
              .toList();
        });
      }
    } catch (e) {
      // Optionally show error
    }
    setState(() => _isLoadingComments = false);
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid book or comment.')));
      return;
    }
    setState(() => _isPostingComment = true);
    try {
      print('Posting comment for bookId: ${widget.bookId}');
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse(ApiConstants.bookComments);
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${authService.accessToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'book_id': widget.bookId,
          'content': text,
        }),
      );
      print('Comment response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        _commentController.clear();
        await _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to post comment: ${response.body}')));
      }
    } catch (e) {
      print('Comment error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: ${e.toString()}')));
    }
    setState(() => _isPostingComment = false);
  }

  Future<void> _loadNote() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse('${ApiConstants.bookNotes}/${widget.bookId}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body);
        _noteController.text = data['content'] ?? '';
      }
    } catch (e) {}
  }

  Future<void> _saveNote() async {
    if (widget.bookId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid book.')));
      return;
    }
    setState(() => _isSavingNote = true);
    try {
      print('Saving note for bookId: ${widget.bookId}');
      final authService = Provider.of<AuthService>(context, listen: false);
      final url = Uri.parse(ApiConstants.bookNotes);
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${authService.accessToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'book_id': widget.bookId,
          'content': _noteController.text.trim(),
        }),
      );
      print('Note response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Note saved!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save note: ${response.body}')));
      }
    } catch (e) {
      print('Note error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: ${e.toString()}')));
    }
    setState(() => _isSavingNote = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(widget.imageUrl,
                    width: 80, height: 120, fit: BoxFit.cover),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(widget.author,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                      Text(widget.category,
                          style: const TextStyle(fontSize: 14)),
                      Row(
                        children: [
                          ...List.generate(
                              5,
                              (i) => Icon(Icons.star,
                                  size: 14,
                                  color: i < widget.rating.floor()
                                      ? Colors.amber
                                      : Colors.grey[300])),
                          const SizedBox(width: 4),
                          Text(widget.rating.toString(),
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: _comments
                        .map((c) => ListTile(
                              leading:
                                  CircleAvatar(child: Text(c['author'][0])),
                              title: Text(c['author']),
                              subtitle: Text(c['content']),
                              trailing: Text(
                                  '${c['createdAt'].hour}:${c['createdAt'].minute}'),
                            ))
                        .toList(),
                  ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration:
                        const InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isPostingComment ? null : _postComment,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Personal Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration:
                  const InputDecoration(hintText: 'Write your note here...'),
              onChanged: (val) {
                // Optionally auto-save
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSavingNote ? null : _saveNote,
              child: _isSavingNote
                  ? const CircularProgressIndicator()
                  : const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
