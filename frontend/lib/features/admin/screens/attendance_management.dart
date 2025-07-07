import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';

class AttendanceRecord {
  final String userId;
  final String userName;
  final DateTime date;
  final String eventType;
  final bool isPresent;
  final String? notes;

  AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.date,
    required this.eventType,
    required this.isPresent,
    this.notes,
  });
}

class AttendanceManagement extends StatefulWidget {
  const AttendanceManagement({Key? key}) : super(key: key);

  @override
  _AttendanceManagementState createState() => _AttendanceManagementState();
}

class _AttendanceManagementState extends State<AttendanceManagement> {
  final List<AttendanceRecord> _attendanceRecords = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedEventType = 'All';
  bool _isLoading = false;
  final List<String> _eventTypes = [
    'All',
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting'
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with Laravel API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      setState(() {
        _attendanceRecords.addAll([
          AttendanceRecord(
            userId: '1',
            userName: 'John Doe',
            date: DateTime.now().subtract(const Duration(days: 1)),
            eventType: 'Sunday Service',
            isPresent: true,
          ),
          AttendanceRecord(
            userId: '2',
            userName: 'Jane Smith',
            date: DateTime.now().subtract(const Duration(days: 1)),
            eventType: 'Sunday Service',
            isPresent: false,
            notes: 'Called in sick',
          ),
          AttendanceRecord(
            userId: '1',
            userName: 'John Doe',
            date: DateTime.now().subtract(const Duration(days: 3)),
            eventType: 'Bible Study',
            isPresent: true,
          ),
        ]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance records: $e')),
      );
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    return _attendanceRecords.where((record) {
      if (_selectedEventType != 'All' &&
          record.eventType != _selectedEventType) {
        return false;
      }
      if (_startDate != null && record.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && record.date.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(localizations.attendanceList),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportAttendanceData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(localizations),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAttendanceList(localizations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAttendanceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _eventTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedEventType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _showDateRangePicker,
                ),
              ],
            ),
            if (_startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Date Range: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList(AppLocalizations localizations) {
    if (_filteredRecords.isEmpty) {
      return const Center(
        child: Text('No attendance records found'),
      );
    }

    return ListView.builder(
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: record.isPresent
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(
                record.isPresent ? Icons.check : Icons.close,
                color: record.isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(record.userName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event: ${record.eventType}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(record.date)}'),
                if (record.notes != null)
                  Text(
                    'Notes: ${record.notes}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editAttendance(record),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAttendance(record),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _showAddAttendanceDialog() async {
    final result = await showDialog<AttendanceRecord>(
      context: context,
      builder: (context) => const AttendanceDialog(),
    );

    if (result != null) {
      setState(() {
        _attendanceRecords.add(result);
      });
    }
  }

  void _editAttendance(AttendanceRecord record) {
    // TODO: Implement edit functionality
  }

  void _deleteAttendance(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance Record'),
        content: Text(
            'Are you sure you want to delete this attendance record for ${record.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _attendanceRecords.remove(record);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportAttendanceData() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting attendance data...')),
    );
  }
}

class AttendanceDialog extends StatefulWidget {
  const AttendanceDialog({Key? key}) : super(key: key);

  @override
  _AttendanceDialogState createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  String? _selectedEventType;
  DateTime? _selectedDate;
  bool _isPresent = true;
  final _notesController = TextEditingController();

  // Mock user data - replace with actual API call
  final List<Map<String, String>> _users = [
    {'id': '1', 'name': 'John Doe'},
    {'id': '2', 'name': 'Jane Smith'},
  ];

  final List<String> _eventTypes = [
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Attendance Record'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'User',
                  border: OutlineInputBorder(),
                ),
                items: _users.map((user) {
                  return DropdownMenuItem(
                    value: user['id'],
                    child: Text(user['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a user';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedEventType = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select an event type';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Present'),
                value: _isPresent,
                onChanged: (value) {
                  setState(() => _isPresent = value);
                },
              ),
              if (!_isPresent)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedDate != null) {
              final user = _users.firstWhere((u) => u['id'] == _selectedUserId);
              Navigator.pop(
                context,
                AttendanceRecord(
                  userId: _selectedUserId!,
                  userName: user['name']!,
                  date: _selectedDate!,
                  eventType: _selectedEventType!,
                  isPresent: _isPresent,
                  notes: _notesController.text.isEmpty
                      ? null
                      : _notesController.text,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
