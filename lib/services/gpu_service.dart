import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class GPU {
  final int? id;
  final String modelName;
  final String brand;
  final int vram;
  final double coreClock;
  final double boostClock;
  final int tdp;
  final int length;
  final int price;
  final String imageURL;

  GPU({
    this.id,
    required this.modelName,
    required this.brand,
    required this.vram,
    required this.coreClock,
    required this.boostClock,
    required this.tdp,
    required this.length,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'brand': brand,
      'vram': vram,
      'core_clock': coreClock,
      'boostclock': boostClock,
      'tdp': tdp,
      'length_mm': length,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory GPU.fromMap(Map<String, dynamic> map) {
    return GPU(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      brand: map['brand'] ?? '',
      vram: map['vram'] ?? 0,
      coreClock: map['core_clock']?.toDouble() ?? 0.0,
      boostClock: map['boostclock']?.toDouble() ?? 0.0,
      tdp: map['tdp'] ?? 0,
      length: map['length_mm'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}
class GPUService {
  static const String tableName = 'GPUtable';

// Add this function to GPUService class


  // Insert a new GPU WITH SYNC
  static Future<int> insertGPU(GPU gpu) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, gpu.toMap());
    
    //  SYNC WITH PYTHON API AFTER ADDING GPU
    print('🔄 Syncing new GPU with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('GPU');
    
    final gpuWithId = gpu.toMap();
    gpuWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(gpuWithId, 'gpu');
    
    print(' GPU added and synced with ID: $id');
    return id;
  }

  static Future<List<GPU>> getAllGPUs() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => GPU.fromMap(e)).toList();
  }

  static Future<GPU?> getGPUById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? GPU.fromMap(result.first) : null;
  }

  static Future<int> updateGPU(GPU gpu) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      gpu.toMap(),
      where: "id = ?",
      whereArgs: [gpu.id],
    );
    
    if (result > 0 && gpu.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('GPU', gpu.id!, gpu.toMap());
    
    }
    
    return result;
  }

  static Future<int> deleteGPU(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('GPU', id);
    }
    
    return result;
  }
  
}
