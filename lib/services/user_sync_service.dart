import 'dart:convert';
import 'package:http/http.dart' as http;

class UserSyncService {
  static const String pythonApiBaseUrl = 'http://10.0.2.2:5000';

  // Sync when a new user is registered
  static Future<void> syncUserAdded(Map<String, dynamic> userData) async {
    print('Syncing new user: ${userData['email']}');
    await _syncUserOperation(
      action: 'add',
      userData: userData,
    );
  }

  // Sync when a user is deleted
  static Future<void> syncUserDeleted(int userId, String email) async {
    print('Syncing user deletion - ID: $userId, Email: $email');
    await _syncUserOperation(
      action: 'delete',
      userData: {'id': userId, 'email': email},
    );
  }

  // Sync when user data is updated
  static Future<void> syncUserUpdated(int userId, Map<String, dynamic> updatedData) async {
    print('Syncing user update - ID: $userId');
    await _syncUserOperation(
      action: 'update',
      userData: {'id': userId, ...updatedData},
    );
  }

  // Generic method to handle all user sync operations
  static Future<void> _syncUserOperation({
    required String action,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonApiBaseUrl/api/sync/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': action,
          'user_data': userData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('User $action sync successful');
      } else {
        print('User $action sync failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error syncing user $action: $e');
      // Consider implementing a retry mechanism or offline queue here
    }
  }

  // Sync user builds
  static Future<void> syncUserBuilds({
    required int userId,
    required List<Map<String, dynamic>> builds,
    String action = 'sync',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonApiBaseUrl/api/sync/user/builds'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'builds': builds,
          'action': action,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('User builds $action sync successful');
      } else {
        print('User builds $action sync failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error syncing user builds: $e');
    }
  }
}
