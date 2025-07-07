import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class NotificationControl extends StatefulWidget {
  const NotificationControl({Key? key}) : super(key: key);

  @override
  _NotificationControlState createState() => _NotificationControlState();
}

class _NotificationControlState extends State<NotificationControl> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'announcement';
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // TODO: Replace with Laravel API call
    setState(() {
      _notifications = [
        {
          'id': '1',
          'title': 'Welcome Message',
          'message': 'Welcome to our app!',
          'type': 'announcement',
          'sentAt': DateTime.now(),
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
          title: Text(localizations.notificationControl),
          bottom: TabBar(
            tabs: [
              Tab(text: localizations.sendNotifications),
              Tab(text: localizations.notificationHistory),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSendNotificationTab(localizations),
            _buildNotificationHistoryTab(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildSendNotificationTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: localizations.notificationType,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'announcement',
                  child: Text(localizations.announcement),
                ),
                DropdownMenuItem(
                  value: 'reminder',
                  child: Text(localizations.reminder),
                ),
                DropdownMenuItem(
                  value: 'alert',
                  child: Text(localizations.alert),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: localizations.title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: localizations.message,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.requiredField;
                }
                return null;
              },
            ),
            if (_selectedType.contains('reminder')) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedTime == null
                    ? localizations.selectTime
                    : 'Time: ${_selectedTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sendNotification,
              child: Text(localizations.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryTab(AppLocalizations localizations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          child: ListTile(
            title: Text(notification['title']),
            subtitle: Text(notification['message']),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle delete notification
              },
              tooltip: localizations.delete,
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final localizations = AppLocalizations.of(context);
      // TODO: Replace with Laravel API call
      setState(() {
        _notifications.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': _titleController.text,
          'message': _messageController.text,
          'type': _selectedType,
          'sentAt': DateTime.now(),
        });
      });

      // Clear form
      _titleController.clear();
      _messageController.clear();
      setState(() => _selectedTime = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.notificationSent)),
      );
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.error}: $e')),
      );
    }
  }
}
