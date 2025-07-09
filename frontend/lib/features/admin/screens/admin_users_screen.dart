import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<Map<String, dynamic>>> _pendingUsersFuture;

  @override
  void initState() {
    super.initState();
    _pendingUsersFuture = _fetchPendingUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return await authService.fetchPendingUsers();
  }

  Future<void> _approveUser(int userId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.approveUser(userId);
    setState(() {
      _pendingUsersFuture = _fetchPendingUsers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('User approved successfully!'),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending User Approvals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending users.'));
          }
          final users = snapshot.data!;
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Text(user['email'] ?? ''),
                trailing: ElevatedButton(
                  onPressed: () => _approveUser(user['id']),
                  child: const Text('Approve'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
