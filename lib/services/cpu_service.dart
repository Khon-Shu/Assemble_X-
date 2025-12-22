import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart'; // Add this import

class CPU {
  final int? id;
  final String modelName;
  final String brand;
  final String socket;
  final int cores;
  final int threads;
  final double baseClock;
  final double boostClock;
  final int tdp;
  final int integratedGraphics;
  final int price;
  final String imageURL;

  CPU({
    this.id,
    required this.modelName,
    required this.brand,
    required this.socket,
    required this.cores,
    required this.threads,
    required this.baseClock,
    required this.boostClock,
    required this.tdp,
    required this.integratedGraphics,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'brand': brand,
      'socket': socket,
      'cores': cores,
      'threads': threads,
      'baseclock': baseClock,
      'boostclock': boostClock,
      'tdp': tdp,
      'integratedgraphics': integratedGraphics,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory CPU.fromMap(Map<String, dynamic> map) {
    return CPU(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      brand: map['brand'] ?? '',
      socket: map['socket'] ?? '',
      cores: map['cores'] ?? 0,
      threads: map['threads'] ?? 0,
      baseClock: map['baseclock']?.toDouble() ?? 0.0,
      boostClock: map['boostclock']?.toDouble() ?? 0.0,
      tdp: map['tdp'] ?? 0,
      integratedGraphics: map['integratedgraphics'] ?? 0,
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class CPUService {
  static const String tableName = 'CPUtable';
  // Add this function to CPUService class


  // Insert a new CPU WITH SYNC
  static Future<int> insertCPU(CPU cpu) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, cpu.toMap());
    
    //  SYNC WITH PYTHON API AFTER ADDING CPU
    print(' Syncing new CPU with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('CPU');
    
    // Also sync the specific component data
    final cpuWithId = cpu.toMap();
    cpuWithId['id'] = id; // Add the generated ID
    await DatabaseSyncService.syncNewComponent(cpuWithId, 'cpu');
    
    print(' CPU added and synced with ID: $id');
    return id;
  }

  // Get all CPUs
  static Future<List<CPU>> getAllCPUs() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => CPU.fromMap(e)).toList();
  }

  // Get CPU by ID
  static Future<CPU?> getCPUById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? CPU.fromMap(result.first) : null;
  }

  // Get CPUs by socket
  static Future<List<CPU>> getCPUsBySocket(String socket) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "socket = ?",
      whereArgs: [socket],
    );
    return result.map((e) => CPU.fromMap(e)).toList();
  }

  // Update CPU WITH SYNC
  static Future<int> updateCPU(CPU cpu) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      cpu.toMap(),
      where: "id = ?",
      whereArgs: [cpu.id],
    );
    
    //  SYNC AFTER UPDATE
    if (result > 0 && cpu.id != null) {
      print(' Syncing updated CPU with recommendation system...');
      await DatabaseSyncService.syncOnProductUpdated('CPU', cpu.id!, cpu.toMap());
      
    }
    
    return result;
  }

  // Delete CPU WITH SYNC
  static Future<int> deleteCPU(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    //  SYNC AFTER DELETE
    if (result > 0) {
      print('🔄 Syncing CPU deletion with recommendation system...');
      await DatabaseSyncService.syncOnProductDeletion('CPU', id);
      // You might want to add a separate sync method for deletions
    }
    
    return result;
  }

  // Bulk insert CPUs WITH SYNC (useful for initial data)
  static Future<void> insertCPUs(List<CPU> cpus) async {
    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    
    for (final cpu in cpus) {
      batch.insert(tableName, cpu.toMap());
    }
    
    await batch.commit();
    
    //  SYNC AFTER BULK INSERT
    print('🔄 Syncing ${cpus.length} CPUs with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('CPU');
  }
}