import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class Storage {
  final int? id;
  final String modelName;
  final String interface;
  final int capacity;
  final int price;
  final String imageURL;

  Storage({
    this.id,
    required this.modelName,
    required this.interface,
    required this.capacity,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'interface': interface,
      'capacity': capacity,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      interface: map['interface'] ?? '',
      capacity: map['capacity'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class StorageService {
  static const String tableName = 'storagetable';

  // Insert a new Storage WITH SYNC
  static Future<int> insertStorage(Storage storage) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, storage.toMap());
    // Add this function to StorageService class
 
    
    //  SYNC WITH PYTHON API AFTER ADDING STORAGE
    print(' Syncing new Storage with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('Storage');
    
    final storageWithId = storage.toMap();
    storageWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(storageWithId, 'storage');
    
    print('Storage added and synced with ID: $id');
    return id;
  }

  static Future<List<Storage>> getAllStorages() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => Storage.fromMap(e)).toList();
  }

  static Future<Storage?> getStorageById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? Storage.fromMap(result.first) : null;
  }

  static Future<int> updateStorage(Storage storage) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      storage.toMap(),
      where: "id = ?",
      whereArgs: [storage.id],
    );
    
    if (result > 0 && storage.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('Storage', storage.id!, storage.toMap());
     
    }
    
    return result;
  }

  static Future<int> deleteStorage(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('Storage', id);
    }
    
    return result;
  }
}