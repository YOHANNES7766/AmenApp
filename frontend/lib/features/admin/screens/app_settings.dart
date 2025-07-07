import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({Key? key}) : super(key: key);

  @override
  _AppSettingsState createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _bibleVersions = [];
  List<Map<String, dynamic>> _languages = [];
  List<Map<String, dynamic>> _faqs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // TODO: Replace with Laravel API call
      setState(() {
        _settings = {
          'darkMode': false,
          'useSystemTheme': true,
          'dailyVerseNotifications': true,
          'prayerTimeReminders': true,
        };
        _bibleVersions = [
          {
            'id': '1',
            'name': 'King James Version',
            'code': 'KJV',
            'isActive': true,
          },
        ];
        _languages = [
          {
            'id': '1',
            'name': 'English',
            'code': 'en',
            'isActive': true,
          },
          {
            'id': '2',
            'name': 'Amharic',
            'code': 'am',
            'isActive': true,
          },
        ];
        _faqs = [
          {
            'id': '1',
            'question': 'How do I reset my password?',
            'answer': 'You can reset your password from the login screen.',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 4,
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
          title: Text(
            localizations.appSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Bible Versions'),
              Tab(text: 'Languages'),
              Tab(text: 'FAQ'),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: [
              _buildGeneralSettings(),
              _buildBibleVersionsTab(),
              _buildLanguagesTab(),
              _buildFAQTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saveSettings,
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.themeSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(localizations.darkMode),
            subtitle: Text(localizations.darkModeDesc),
            value: _settings['darkMode'] ?? false,
            onChanged: (value) {
              setState(() => _settings['darkMode'] = value);
            },
          ),
          SwitchListTile(
            title: Text(localizations.systemTheme),
            value: _settings['useSystemTheme'] ?? true,
            onChanged: (value) {
              setState(() => _settings['useSystemTheme'] = value);
            },
          ),
          const Divider(),
          Text(
            localizations.notificationSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(localizations.dailyVerseNotifications),
            value: _settings['dailyVerseNotifications'] ?? true,
            onChanged: (value) {
              setState(() => _settings['dailyVerseNotifications'] = value);
            },
          ),
          SwitchListTile(
            title: Text(localizations.prayerTimeReminders),
            value: _settings['prayerTimeReminders'] ?? true,
            onChanged: (value) {
              setState(() => _settings['prayerTimeReminders'] = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBibleVersionsTab() {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(localizations.bibleVersions),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddBibleVersionDialog();
            },
            tooltip: localizations.addBibleVersion,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _bibleVersions.length,
            itemBuilder: (context, index) {
              final version = _bibleVersions[index];
              return SwitchListTile(
                title: Text(version['name']),
                subtitle: Text(version['code']),
                value: version['isActive'],
                onChanged: (value) {
                  setState(() {
                    _bibleVersions[index]['isActive'] = value;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesTab() {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(localizations.languages),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddLanguageDialog();
            },
            tooltip: localizations.addLanguage,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              return SwitchListTile(
                title: Text(language['name']),
                subtitle: Text(language['code']),
                value: language['isActive'],
                onChanged: (value) {
                  setState(() {
                    _languages[index]['isActive'] = value;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFAQTab() {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(localizations.faq),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showEditFAQDialog(-1, null);
            },
            tooltip: localizations.addFAQ,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _faqs.length,
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return ExpansionTile(
                title: Text(faq['question']),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq['answer']),
                  ),
                  OverflowBar(
                    children: [
                      TextButton(
                        onPressed: () => _showEditFAQDialog(index, faq),
                        child: Text(localizations.editFAQ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _faqs.removeAt(index);
                          });
                        },
                        child: Text(localizations.delete),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddBibleVersionDialog() {
    final localizations = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addBibleVersion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Version Name'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Language Code'),
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
              final newVersion = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': nameController.text,
                'code': codeController.text,
                'isActive': true,
              };
              setState(() => _bibleVersions.add(newVersion));
              Navigator.pop(context);
            },
            child: Text(localizations.add),
          ),
        ],
      ),
    );
  }

  void _showAddLanguageDialog() {
    final localizations = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Language Name'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Language Code'),
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
              final newLanguage = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': nameController.text,
                'code': codeController.text,
                'isActive': true,
              };
              setState(() => _languages.add(newLanguage));
              Navigator.pop(context);
            },
            child: Text(localizations.add),
          ),
        ],
      ),
    );
  }

  void _showEditFAQDialog(int index, Map<String, dynamic>? faq) {
    final localizations = AppLocalizations.of(context);
    final questionController =
        TextEditingController(text: faq?['question'] ?? '');
    final answerController = TextEditingController(text: faq?['answer'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? localizations.addFAQ : localizations.editFAQ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(labelText: 'Answer'),
              maxLines: 3,
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
              final faqs = List<Map<String, dynamic>>.from(_faqs);
              final newFaq = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'question': questionController.text,
                'answer': answerController.text,
              };
              if (index == -1) {
                faqs.add(newFaq);
              } else {
                faqs[index] = newFaq;
              }
              setState(() => _faqs = faqs);
              Navigator.pop(context);
            },
            child: Text(index == -1 ? localizations.add : localizations.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      // TODO: Replace with Laravel API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }
}
