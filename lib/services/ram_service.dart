import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class RAM {
  final int? id;
  final String modelName;
  final String memoryType;
  final int capacity;
  final int speed;
  final int modules;
  final int price;
  final String imageURL;

  RAM({
    this.id,
    required this.modelName,
    required this.memoryType,
    required this.capacity,
    required this.speed,
    required this.modules,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'memory_type': memoryType,
      'capacity': capacity,
      'speed': speed,
      'modules': modules,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory RAM.fromMap(Map<String, dynamic> map) {
    return RAM(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      memoryType: map['memory_type'] ?? '',
      capacity: map['capacity'] ?? 0,
      speed: map['speed'] ?? 0,
      modules: map['modules'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class RAMService {
  static const String tableName = 'RAMtable';
// Add this function to RAMService class

  // Insert a new RAM WITH SYNC
  static Future<int> insertRAM(RAM ram) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, ram.toMap());
    
    // ✅ SYNC WITH PYTHON API AFTER ADDING RAM
    print(' Syncing new RAM with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('RAM');
    
    final ramWithId = ram.toMap();
    ramWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(ramWithId, 'ram');
    
    print(' RAM added and synced with ID: $id');
    return id;
  }

  static Future<List<RAM>> getAllRAMs() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => RAM.fromMap(e)).toList();
  }

  static Future<RAM?> getRAMById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? RAM.fromMap(result.first) : null;
  }

  static Future<int> updateRAM(RAM ram) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      ram.toMap(),
      where: "id = ?",
      whereArgs: [ram.id],
    );
    
    if (result > 0 && ram.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('RAM', ram.id!, ram.toMap());
      
    }
    
    return result;
  }

  static Future<int> deleteRAM(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('RAM', id);
    }
    
    return result;
  }
}