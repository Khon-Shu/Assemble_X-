import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({Key? key}) : super(key: key);

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<bool> _confirmDelete(int userId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: const Text(
              'Are you sure you want to delete this user and all their builds? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;
      if (!mounted) return false;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _databaseService.deleteUser(userId);

      if (!mounted) return false;
      Navigator.of(context, rootNavigator: true).pop();

      if (result > 0) {
        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User and their builds deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete user. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        String errorMessage = 'Failed to delete user';
        if (e.toString().contains('FOREIGN KEY constraint failed')) {
          errorMessage = 'Cannot delete user. Some data is still referenced.';
        } else if (e.toString().contains('database is locked')) {
          errorMessage = 'Database is busy. Please try again in a moment.';
        } else {
          errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final db = await _databaseService.database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='userinfo'",
      );

      if (tables.isEmpty) {
        throw Exception('Users table does not exist');
      }

      final List<Map<String, dynamic>> users = await db.rawQuery('''
        SELECT 
          u.*,
          (SELECT COUNT(*) FROM user_build_table WHERE user_id = u.id) as build_count
        FROM userinfo u
        ORDER BY u.id DESC
      ''');

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading users: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: false),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadUsers,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Display total users
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Users of \nAssembleX',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    SizedBox(width:30),
                                    LottieBuilder.asset(
                                      'assets/lottie/user.json',
                                      height: 180,
                                      width: 180,
                                      fit: BoxFit.fill,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0, left: 16),
                                child: Divider(thickness:1 , color: Colors.black),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _users.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                    color: Colors.black26,
                                    thickness: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    final firstName =
                                        user['firstname']?.toString() ?? 'Unknown';
                                    final lastName = user['lastname']?.toString() ?? '';
                                    final email = user['email']?.toString() ?? 'No email';
                                    final userId = user['id']?.toString() ?? 'N/A';

                                    final avatarText = firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : '?';

                                    final profilePic = user['profile_pic']?.toString();
                                    final buildCount = user['build_count'] ?? 0;

                                    return ListTile(
                                      leading: profilePic != null && profilePic.isNotEmpty
                                          ? CircleAvatar(
                                              radius: 24,
                                              backgroundImage:
                                                  NetworkImage(profilePic),
                                            )
                                          : CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.blue.shade100,
                                              child: Text(
                                                avatarText,
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                      title: Text(
                                        '$firstName $lastName'.trim(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text('$email\nBuilds: $buildCount'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () => _confirmDelete(user['id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: AdminBottomNavBar(selectedindex: 2),
            ),
          ],
        ),
      ),
    );
  }
}
