import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class Motherboard {
  final int? id;
  final String modelName;
  final String brand;
  final String socket;
  final String chipset;
  final String formFactor;
  final String memoryType;
  final int memorySlots;
  final int maxMemory;
  final int price;
  final String imageURL;

  Motherboard({
    this.id,
    required this.modelName,
    required this.brand,
    required this.socket,
    required this.chipset,
    required this.formFactor,
    required this.memoryType,
    required this.memorySlots,
    required this.maxMemory,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'brand': brand,
      'socket': socket,
      'chipset': chipset,
      'form_factor': formFactor,
      'memory_type': memoryType,
      'memory_slots': memorySlots,
      'max_memory': maxMemory,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory Motherboard.fromMap(Map<String, dynamic> map) {
    return Motherboard(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      brand: map['brand'] ?? '',
      socket: map['socket'] ?? '',
      chipset: map['chipset'] ?? '',
      formFactor: map['form_factor'] ?? '',
      memoryType: map['memory_type'] ?? '',
      memorySlots: map['memory_slots'] ?? 0,
      maxMemory: map['max_memory'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class MotherboardService {
  static const String tableName = 'motherboardtable';
  // Add this function to MotherboardService class


  // Insert a new Motherboard WITH SYNC
  static Future<int> insertMotherboard(Motherboard motherboard) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, motherboard.toMap());
    
    //  SYNC WITH PYTHON API AFTER ADDING MOTHERBOARD
    print(' Syncing new Motherboard with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('Motherboard');
    
    final moboWithId = motherboard.toMap();
    moboWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(moboWithId, 'motherboard');
    
    print(' Motherboard added and synced with ID: $id');
    return id;
  }

  static Future<List<Motherboard>> getAllMotherboards() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => Motherboard.fromMap(e)).toList();
  }

  static Future<Motherboard?> getMotherboardById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? Motherboard.fromMap(result.first) : null;
  }

  static Future<int> updateMotherboard(Motherboard motherboard) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      motherboard.toMap(),
      where: "id = ?",
      whereArgs: [motherboard.id],
    );
    
    if (result > 0 && motherboard.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('Motherboard', motherboard.id!, motherboard.toMap());
      
    }
    
    return result;
  }

  static Future<int> deleteMotherboard(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('Motherboard', id);
    }
    
    return result;
  }
}