import 'package:flutter/material.dart';
import 'admin_home_screen.dart';
import '../../../core/localization/app_localizations.dart';

class FeedbackManagement extends StatefulWidget {
  const FeedbackManagement({Key? key}) : super(key: key);

  @override
  _FeedbackManagementState createState() => _FeedbackManagementState();
}

class _FeedbackManagementState extends State<FeedbackManagement> {
  String _filter = 'pending';
  List<Map<String, dynamic>> _testimonials = [];
  List<Map<String, dynamic>> _appFeedback = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Replace with Laravel API call
    setState(() {
      _testimonials = [
        {
          'id': '1',
          'title': 'Great App',
          'userName': 'John Doe',
          'status': 'pending',
          'content': 'This app has been very helpful',
          'createdAt': DateTime.now(),
        },
      ];
      _appFeedback = [
        {
          'id': '1',
          'category': 'General',
          'content': 'Love the app!',
          'rating': 5,
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
          title: Text(localizations.feedbackManagement),
          bottom: TabBar(
            tabs: [
              Tab(text: localizations.testimonials),
              Tab(text: localizations.appFeedback),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _filter = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pending',
                  child: Text(localizations.pending),
                ),
                PopupMenuItem(
                  value: 'approved',
                  child: Text(localizations.approved),
                ),
                PopupMenuItem(
                  value: 'rejected',
                  child: Text(localizations.rejected),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTestimonialsTab(localizations),
            _buildAppFeedbackTab(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialsTab(AppLocalizations localizations) {
    final filteredTestimonials =
        _testimonials.where((t) => t['status'] == _filter).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTestimonials.length,
      itemBuilder: (context, index) {
        final testimonial = filteredTestimonials[index];
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
                      child: Text(testimonial['userName'][0]),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimonial['userName'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _formatDate(testimonial['createdAt']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  testimonial['title'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  testimonial['content'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _rejectTestimonial(testimonial['id']),
                      child: Text(localizations.reject),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveTestimonial(testimonial['id']),
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

  Widget _buildAppFeedbackTab(AppLocalizations localizations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appFeedback.length,
      itemBuilder: (context, index) {
        final feedback = _appFeedback[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      feedback['category'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          feedback['rating'].toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feedback['content'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(feedback['createdAt']),
                  style: Theme.of(context).textTheme.bodySmall,
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

  void _approveTestimonial(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _testimonials.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _testimonials[index]['status'] = 'approved';
      }
    });
  }

  void _rejectTestimonial(String id) {
    // TODO: Implement Laravel API call
    setState(() {
      final index = _testimonials.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _testimonials[index]['status'] = 'rejected';
      }
    });
  }
}
