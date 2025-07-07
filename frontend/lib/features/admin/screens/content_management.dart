import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'admin_home_screen.dart';

class ContentManagement extends StatefulWidget {
  const ContentManagement({Key? key}) : super(key: key);

  @override
  _ContentManagementState createState() => _ContentManagementState();
}

class _ContentManagementState extends State<ContentManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _verses = [];
  List<Map<String, dynamic>> _commentaries = [];
  List<Map<String, dynamic>> _devotionals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Replace with Laravel API call
    setState(() {
      _verses = [
        {
          'id': '1',
          'verse': 'For God so loved the world...',
          'reference': 'John 3:16',
        },
      ];
      _commentaries = [
        {
          'id': '1',
          'title': 'Matthew Commentary',
          'author': 'John Smith',
        },
      ];
      _devotionals = [
        {
          'id': '1',
          'title': 'Daily Strength',
          'author': 'Jane Doe',
        },
      ];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
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
        title: Text(localizations.contentManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.versesOfDay),
            Tab(text: localizations.commentaries),
            Tab(text: localizations.devotionals),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVersesOfTheDay(),
          _buildCommentaries(),
          _buildDevotionals(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContentDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVersesOfTheDay() {
    return ListView.builder(
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(verse['verse'] ?? ''),
            subtitle: Text(verse['reference'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editVerse(verse['id'], verse),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteVerse(verse['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentaries() {
    return ListView.builder(
      itemCount: _commentaries.length,
      itemBuilder: (context, index) {
        final commentary = _commentaries[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(commentary['title'] ?? ''),
            subtitle: Text(commentary['author'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _editCommentary(commentary['id'], commentary),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCommentary(commentary['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevotionals() {
    return ListView.builder(
      itemCount: _devotionals.length,
      itemBuilder: (context, index) {
        final devotional = _devotionals[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(devotional['title'] ?? ''),
            subtitle: Text(devotional['author'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _editDevotional(devotional['id'], devotional),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteDevotional(devotional['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddContentDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${localizations.add} ${_getCurrentContentType(localizations)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: localizations.title),
              onChanged: (value) {
                // Handle title input
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: localizations.content),
              maxLines: 3,
              onChanged: (value) {
                // Handle content input
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              // Handle save
              Navigator.pop(context);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  String _getCurrentContentType(AppLocalizations localizations) {
    switch (_tabController.index) {
      case 0:
        return localizations.versesOfDay;
      case 1:
        return localizations.commentaries;
      case 2:
        return localizations.devotionals;
      default:
        return '';
    }
  }

  void _editVerse(String id, Map<String, dynamic> verse) {
    // Implement verse editing
  }

  void _deleteVerse(String id) {
    // Implement verse deletion
  }

  void _editCommentary(String id, Map<String, dynamic> commentary) {
    // Implement commentary editing
  }

  void _deleteCommentary(String id) {
    // Implement commentary deletion
  }

  void _editDevotional(String id, Map<String, dynamic> devotional) {
    // Implement devotional editing
  }

  void _deleteDevotional(String id) {
    // Implement devotional deletion
  }
}
