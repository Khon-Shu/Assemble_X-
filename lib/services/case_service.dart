import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class Case {
  final int? id;
  final String modelName;
  final String brand;
  final String formFactor;
  final int maxGpuLength;
  final int estimatedPower;
  final int price;
  final String imageURL;

  Case({
    this.id,
    required this.modelName,
    required this.brand,
    required this.formFactor,
    required this.maxGpuLength,
    required this.estimatedPower,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'brand': brand,
      'form_factor': formFactor,
      'max_gpu_length': maxGpuLength,
      'estimated_power': estimatedPower,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory Case.fromMap(Map<String, dynamic> map) {
    return Case(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      brand: map['brand'] ?? '',
      formFactor: map['form_factor'] ?? '',
      maxGpuLength: map['max_gpu_length'] ?? 0,
      estimatedPower: map['estimated_power'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class CaseService {
  static const String tableName = 'casetable';
  // Add this function to CaseService class


  // Insert a new Case WITH SYNC
  static Future<int> insertCase(Case pcCase) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, pcCase.toMap());
    
    // SYNC WITH PYTHON API AFTER ADDING CASE
    print(' Syncing new Case with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('Case');
    
    final caseWithId = pcCase.toMap();
    caseWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(caseWithId, 'case');
    
    print(' Case added and synced with ID: $id');
    return id;
  }

  static Future<List<Case>> getAllCases() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => Case.fromMap(e)).toList();
  }

  static Future<Case?> getCaseById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? Case.fromMap(result.first) : null;
  }

  static Future<int> updateCase(Case pcCase) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      pcCase.toMap(),
      where: "id = ?",
      whereArgs: [pcCase.id],
    );
    
    if (result > 0 && pcCase.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('Case', pcCase.id!, pcCase.toMap() );
      
    }
    
    return result;
  }

  static Future<int> deleteCase(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('Case', id);
    }
    
    return result;
  }
}