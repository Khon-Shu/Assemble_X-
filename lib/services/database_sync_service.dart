import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class DatabaseSyncService {
  static const String pythonApiBaseUrl = 'http://10.0.2.2:5000';
  
  // Sync when new product is added
  static Future<void> syncOnProductAdded(String componentType) async {
    print(' Syncing database after $componentType added...');
    await _syncFullDatabase();
  }

  static Future<void> syncOnProductDeletion(String componentType, int componentId)async{
    print(' Syncing database after $componentType deleted');
    await _syncComponentDeletion(componentType, componentId);
    
  }

    static Future<void> syncOnProductUpdated(String componentType, int componentId, Map<String, dynamic> updatedData) async {
    print('🔄 Syncing update of $componentType ID $componentId...');
    await _syncComponentUpdate(componentType, componentId, updatedData);
  }
  

  // Full database sync
  static Future<void> _syncFullDatabase() async {
  try {
    final databasePath = await getDatabasesPath();
    final dbFile = File('$databasePath/assemble_db.db');
    
    if (await dbFile.exists()) {
      // Read database as bytes
      final dbBytes = await dbFile.readAsBytes();
      
      // Convert to base64 for transmission
      final base64Db = base64Encode(dbBytes);
      
      // Send to Python API - CORRECT ENDPOINT
      final response = await http.post(
        Uri.parse('$pythonApiBaseUrl/api/sync/database'), // Correct endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'database_data': base64Db,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print(' Database synced successfully with Python API');
      } else {
        print(' Database sync failed: ${response.statusCode} - ${response.body}');
      }
    }
  } catch (e) {
    print('Error syncing database: $e');
  }
}

  static Future<void> _syncComponentDeletion(String componentType, int componentId)async{
    try{
      final response = await http.post(
        Uri.parse('$pythonApiBaseUrl/api/sync/component'),
        headers: {'Content-Type':'application/json'},
        body: json.encode({
          'component_id': componentId,
          'category': componentType.toLowerCase(),
          'action': 'delete',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        })
      );
      if(response.statusCode == 200){
          print('$componentId Succesfully Deleted');
      }
      else{
        print('Failed to Delete the component');
      }
    }
    catch(e){
      print('Failed to delete the product $e');
    }
      }
      
  // Sync individual component
 static Future<void> syncNewComponent(Map<String, dynamic> component, String category) async {
  try {
    final response = await http.post(
      Uri.parse('$pythonApiBaseUrl/api/sync/component'), // ✅ Correct endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'component': component,
        'category': category,
        'action': 'add',
      }),
    );

    if (response.statusCode == 200) {
      print(' $category synced with Python API');
    } else {
      print(' $category sync failed: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print(' Error syncing $category: $e');
  }
}
 static Future<void> _syncComponentUpdate(String componentType, int componentId, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonApiBaseUrl/api/sync/component'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'component': updatedData,
          'component_id': componentId,
          'category': componentType.toLowerCase(),
          'action': 'update', // ✅ This tells Python it's an UPDATE
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        print(' $componentType update synced with Python API');
      } else {
        print(' $componentType update sync failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error syncing $componentType update: $e');
    }
  }
}

