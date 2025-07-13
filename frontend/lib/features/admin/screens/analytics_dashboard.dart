import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with Laravel API call
      setState(() {
        _analytics = {
          'totalUsers': 241,
          'activeUsers': 134,
          'totalPrayerRequests': 56,
          'totalEvents': 12,
          'userGrowth': [10, 20, 30, 40, 50, 60, 70],
          'dailyActiveUsers': 150,
          'avgSessionDuration': 1800,
          'activityByTime': {'Morning': 200, 'Afternoon': 150, 'Evening': 300},
          'completionRates': {
            'Completed': 60,
            'In Progress': 30,
            'Not Started': 10
          },
          'totalDevotionals': 45,
          'totalComments': 89,
          'popularVerses': [
            {'title': 'John 3:16', 'count': 120},
            {'title': 'Psalm 23:1', 'count': 95},
          ],
          'popularDevotionals': [
            {'title': 'Finding Peace', 'count': 78},
            {'title': 'Daily Strength', 'count': 65},
          ],
          'upcomingEvents': 5,
          'avgEventAttendance': 45,
          'eventAttendance': {'Event 1': 50, 'Event 2': 40, 'Event 3': 60},
          'popularEvents': [
            {'title': 'Sunday Service', 'count': 120},
            {'title': 'Bible Study', 'count': 85},
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
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
          title: Text(localizations.analytics),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                _loadAnalytics();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'week',
                  child: Text('Last Week'),
                ),
                const PopupMenuItem(
                  value: 'month',
                  child: Text('Last Month'),
                ),
                const PopupMenuItem(
                  value: 'year',
                  child: Text('Last Year'),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'User Activity'),
              Tab(text: 'Content'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildUserActivityTab(),
            _buildContentTab(),
            _buildEventsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            localizations.totalUsers,
            _analytics['totalUsers']?.toString() ?? '0',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.activeUsers,
            _analytics['activeUsers']?.toString() ?? '0',
            Icons.person_outline,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.prayerRequests,
            _analytics['totalPrayerRequests']?.toString() ?? '0',
            Icons.person_pin_circle,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.events,
            _analytics['totalEvents']?.toString() ?? '0',
            Icons.event,
            Colors.orange,
          ),
          const SizedBox(height: 24),
          if (_analytics['userGrowth'] != null)
            _buildLineChart(
              'User Growth',
              _analytics['userGrowth'],
            ),
        ],
      ),
    );
  }

  Widget _buildUserActivityTab() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            localizations.dailyActiveUsers,
            _analytics['dailyActiveUsers']?.toString() ?? '0',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.averageSessionDuration,
            _formatDuration(_analytics['avgSessionDuration'] ?? 0),
            Icons.timer,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          if (_analytics['activityByTime'] != null)
            _buildBarChart(
              'Activity by Time of Day',
              _analytics['activityByTime'],
            ),
          const SizedBox(height: 24),
          if (_analytics['completionRates'] != null)
            _buildPieChart(
              'Devotion Completion Rates',
              _analytics['completionRates'],
            ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            localizations.totalDevotionals,
            _analytics['totalDevotionals']?.toString() ?? '0',
            Icons.book,
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.totalComments,
            _analytics['totalComments']?.toString() ?? '0',
            Icons.comment,
            Colors.teal,
          ),
          const SizedBox(height: 24),
          if (_analytics['popularVerses'] != null)
            _buildPopularContentList(
              localizations.mostAccessedVerses,
              _analytics['popularVerses'],
            ),
          const SizedBox(height: 24),
          if (_analytics['popularDevotionals'] != null)
            _buildPopularContentList(
              localizations.popularDevotionals,
              _analytics['popularDevotionals'],
            ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            localizations.upcomingEvents,
            _analytics['upcomingEvents']?.toString() ?? '0',
            Icons.event,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            localizations.averageAttendance,
            _analytics['avgEventAttendance']?.toString() ?? '0',
            Icons.groups,
            Colors.deepPurple,
          ),
          const SizedBox(height: 24),
          if (_analytics['eventAttendance'] != null)
            _buildBarChart(
              'Event Attendance',
              _analytics['eventAttendance'],
            ),
          const SizedBox(height: 24),
          if (_analytics['popularEvents'] != null)
            _buildPopularContentList(
              localizations.popularEvents,
              _analytics['popularEvents'],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    AppLocalizations.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(String title, List<dynamic> data) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(data.length, (index) {
                        return FlSpot(index.toDouble(), data[index].toDouble());
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String title, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.entries.map((entry) {
                    return BarChartGroupData(
                      x: data.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(String title, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: entry.key,
                      color: Colors.primaries[
                          data.keys.toList().indexOf(entry.key) %
                              Colors.primaries.length],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularContentList(String title, List<dynamic> items) {
    AppLocalizations.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Text('${index + 1}'),
                  title: Text(item['title'] ?? ''),
                  trailing: Text(
                    item['count']?.toString() ?? '0',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
