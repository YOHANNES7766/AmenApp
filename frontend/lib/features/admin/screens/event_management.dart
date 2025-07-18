import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class EventManagement extends StatefulWidget {
  const EventManagement({Key? key}) : super(key: key);

  @override
  _EventManagementState createState() => _EventManagementState();
}

class _EventManagementState extends State<EventManagement> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _eventTitle = '';
  String _eventDescription = '';
  String _eventLocation = '';
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // TODO: Replace with Laravel API call
    setState(() {
      _events = [
        {
          'id': '1',
          'title': 'Sunday Service',
          'description': 'Weekly worship service',
          'location': 'Main Sanctuary',
          'date': DateTime.now().add(const Duration(days: 1)),
          'time': '10:00 AM',
          'rsvps': [],
        },
      ];
    });
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
        title: Text(localizations.eventManagement),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(event['title'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${_formatDate(event['date'])}'),
                        Text('Time: ${event['time']}'),
                        Text('Location: ${event['location']}'),
                        Text('RSVPs: ${event['rsvps']?.length ?? 0}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editEvent(event['id'], event),
                          tooltip: localizations.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteEvent(event['id']),
                          tooltip: localizations.delete,
                        ),
                        IconButton(
                          icon: const Icon(Icons.people),
                          onPressed: () => _viewRSVPs(event['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () => _sendReminder(event['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(localizations),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addNew),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localizations.title,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) => _eventTitle = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localizations.content,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _eventDescription = value!,
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: localizations.location),
                  onSaved: (value) => _eventLocation = value!,
                ),
                ListTile(
                  title: Text(_selectedDate == null
                      ? localizations.selectDate
                      : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
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
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _createEvent();
                Navigator.pop(context);
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  Future<void> _createEvent() async {
    try {
      // TODO: Replace with Laravel API call
      setState(() {
        _events.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': _eventTitle,
          'description': _eventDescription,
          'location': _eventLocation,
          'date': _selectedDate,
          'time': _selectedTime?.format(context),
          'createdAt': DateTime.now(),
          'rsvps': [],
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }

  void _editEvent(String id, Map<String, dynamic> event) {
    // Implement event editing
  }

  void _deleteEvent(String id) {
    // Implement event deletion
  }

  void _viewRSVPs(String eventId) {
    // Implement RSVP viewing
  }

  void _sendReminder(String eventId) {
    // Implement reminder sending
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date set';
    if (date is DateTime) {
      return DateFormat('MMM dd, yyyy').format(date);
    }
    return date.toString();
  }

}
