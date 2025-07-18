import 'package:flutter/material.dart';
import 'package:amen_app/core/localization/app_localizations.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  static void refreshUsers(BuildContext context) {
    final state = context.findAncestorStateOfType<_UserManagementState>();
    state?._loadUsers();
  }

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _newUserName = '';
  String _newUserEmail = '';
  String _newUserRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _users = [
        {'name': 'John Doe', 'email': 'john@example.com', 'role': 'admin'},
        {'name': 'Jane Smith', 'email': 'jane@example.com', 'role': 'user'},
      ];
      _isLoading = false;
    });
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    // TODO: Implement edit user dialog
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    // TODO: Implement delete confirmation dialog
  }

  void showAddUserDialog() async {
    final localizations = AppLocalizations.of(context);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.addNew),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: localizations.userName),
              onChanged: (value) => _newUserName = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: localizations.email),
              onChanged: (value) => _newUserEmail = value,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: localizations.status),
              value: _newUserRole,
              items: [
                DropdownMenuItem(
                    value: 'user', child: Text(localizations.user)),
                DropdownMenuItem(
                    value: 'admin', child: Text(localizations.admin)),
              ],
              onChanged: (value) {
                if (value != null) {
                  _newUserRole = value;
                }
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
              Navigator.pop(context, {
                'name': _newUserName,
                'email': _newUserEmail,
                'role': _newUserRole,
              });
            },
            child: Text(localizations.add),
          ),
        ],
      ),
    );

    if (result != null) {
      // TODO: Implement user creation with API
      setState(() {
        _users.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.userManagement),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.search,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: Text(localizations.loading))
                  : ListView.builder(
                      itemCount: _users
                          .where((user) =>
                              user['name']
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              user['email']
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .length,
                      itemBuilder: (context, index) {
                        final filteredUsers = _users
                            .where((user) =>
                                user['name']
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                user['email']
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))
                            .toList();
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(user['name'][0]),
                            ),
                            title: Text(user['name']),
                            subtitle: Text(user['email']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(user['role']),
                                  backgroundColor: user['role'] == 'admin'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showEditUserDialog(user);
                                        break;
                                      case 'delete':
                                        _showDeleteConfirmation(user);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(localizations.edit),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(localizations.delete),
                                    ),
                                  ],
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_management_fab',
        onPressed: showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
