import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class Cooling {
  final int? id;
  final String modelName;
  final String type;
  final String supportedSockets;
  final int price;
  final String imageURL;

  Cooling({
    this.id,
    required this.modelName,
    required this.type,
    required this.supportedSockets,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'type': type,
      'supported_sockets': supportedSockets,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory Cooling.fromMap(Map<String, dynamic> map) {
    return Cooling(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      type: map['type'] ?? '',
      supportedSockets: map['supported_sockets'] ?? '',
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class CoolingService {
  static const String tableName = 'coolingtable';
  // Add this function to CoolingService class


  // Insert a new Cooling WITH SYNC
  static Future<int> insertCooling(Cooling cooling) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, cooling.toMap());
    
    // ✅ SYNC WITH PYTHON API AFTER ADDING COOLING
    print('🔄 Syncing new Cooling with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('Cooling');
    
    final coolingWithId = cooling.toMap();
    coolingWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(coolingWithId, 'cooling');
    
    print('✅ Cooling added and synced with ID: $id');
    return id;
  }

  static Future<List<Cooling>> getAllCoolings() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => Cooling.fromMap(e)).toList();
  }

  static Future<Cooling?> getCoolingById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? Cooling.fromMap(result.first) : null;
  }

  static Future<int> updateCooling(Cooling cooling) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      cooling.toMap(),
      where: "id = ?",
      whereArgs: [cooling.id],
    );
    
    if (result > 0 && cooling.id !=null) {
      await DatabaseSyncService.syncOnProductUpdated('Cooling', cooling.id!, cooling.toMap());
      
    }
    
    return result;
  }

  static Future<int> deleteCooling(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('Cooling', id);
    }
    
    return result;
  }
}