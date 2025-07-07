import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class PrayerModeration extends StatefulWidget {
  const PrayerModeration({super.key});

  @override
  State<PrayerModeration> createState() => _PrayerModerationState();
}

class _PrayerModerationState extends State<PrayerModeration> {
  // TODO: Replace with Laravel API calls
  final List<Map<String, dynamic>> _prayers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Mock data - replace with Laravel API call
    setState(() {
      _prayers.addAll([
        {
          'id': '1',
          'userName': 'John Doe',
          'prayerText': 'Praying for peace in our community',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'pending',
        },
        {
          'id': '2',
          'userName': 'Jane Smith',
          'prayerText': 'Healing for my family',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'status': 'approved',
        },
      ]);
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
        title: Text(localizations.prayerModeration),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          final prayer = _prayers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prayer['userName'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _formatDate(prayer['timestamp']),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prayer['prayerText'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _deletePrayer(prayer['id']),
                        child: Text(localizations.delete),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _updatePrayerStatus(prayer['id'], 'approved'),
                        child: Text(localizations.approve),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _updatePrayerStatus(String id, String status) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _prayers.indexWhere((p) => p['id'] == id);
      if (index != -1) {
        _prayers[index]['status'] = status;
      }
    });
  }

  void _deletePrayer(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      _prayers.removeWhere((p) => p['id'] == id);
    });
  }
}
