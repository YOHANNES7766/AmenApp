import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class CommentaryModeration extends StatefulWidget {
  const CommentaryModeration({Key? key}) : super(key: key);

  @override
  _CommentaryModerationState createState() => _CommentaryModerationState();
}

class _CommentaryModerationState extends State<CommentaryModeration> {
  String _filter = 'all';
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Replace with Laravel API call
    setState(() {
      _notes = [
        {
          'id': '1',
          'title': 'Matthew 5 Commentary',
          'content': 'This passage talks about the beatitudes...',
          'author': 'John Doe',
          'status': 'pending',
          'reportCount': 0,
          'createdAt': DateTime.now(),
        },
      ];
      _comments = [
        {
          'id': '1',
          'content': 'Great insight on this verse!',
          'author': 'Jane Smith',
          'status': 'pending',
          'reportCount': 0,
          'createdAt': DateTime.now(),
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHomeScreen(),
                ),
              );
            },
          ),
          title: Text(localizations.commentaryModeration),
          bottom: TabBar(
            tabs: [
              Tab(text: localizations.notes),
              Tab(text: localizations.comments),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _filter = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Text(localizations.allContent),
                ),
                PopupMenuItem(
                  value: 'reported',
                  child: Text(localizations.reported),
                ),
                PopupMenuItem(
                  value: 'approved',
                  child: Text(localizations.approved),
                ),
                PopupMenuItem(
                  value: 'removed',
                  child: Text(localizations.removed),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildNotesTab(localizations),
            _buildCommentsTab(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab(AppLocalizations localizations) {
    final filteredNotes = _filter == 'all'
        ? _notes
        : _notes.where((note) => note['status'] == _filter).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(note['author'][0]),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note['author'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _formatDate(note['createdAt']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (note['reportCount'] > 0)
                      Chip(
                        label: Text(
                          '${note['reportCount']} ${localizations.reportCount}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  note['title'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  note['content'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _removeNote(note['id']),
                      child: Text(localizations.remove),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveNote(note['id']),
                      child: Text(localizations.approve),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab(AppLocalizations localizations) {
    final filteredComments = _filter == 'all'
        ? _comments
        : _comments.where((comment) => comment['status'] == _filter).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredComments.length,
      itemBuilder: (context, index) {
        final comment = filteredComments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(comment['author'][0]),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['author'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _formatDate(comment['createdAt']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (comment['reportCount'] > 0)
                      Chip(
                        label: Text(
                          '${comment['reportCount']} ${localizations.reportCount}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  comment['content'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _removeComment(comment['id']),
                      child: Text(localizations.remove),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveComment(comment['id']),
                      child: Text(localizations.approve),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _approveNote(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _notes.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notes[index]['status'] = 'approved';
      }
    });
  }

  void _removeNote(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _notes.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notes[index]['status'] = 'removed';
      }
    });
  }

  void _approveComment(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _comments.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _comments[index]['status'] = 'approved';
      }
    });
  }

  void _removeComment(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _comments.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _comments[index]['status'] = 'removed';
      }
    });
  }
}
