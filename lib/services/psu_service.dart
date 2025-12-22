import 'package:assemblex/services/database_service.dart';
import 'database_sync_service.dart';

class PSU {
  final int? id;
  final String modelName;
  final String brand;
  final int wattage;
  final String formFactor;
  final String efficiencyRating;
  final int price;
  final String imageURL;

  PSU({
    this.id,
    required this.modelName,
    required this.brand,
    required this.wattage,
    required this.formFactor,
    required this.efficiencyRating,
    required this.price,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'brand': brand,
      'wattage': wattage,
      'form_factor': formFactor,
      'efficiency_rating': efficiencyRating,
      'price': price,
      'imageURL': imageURL,
    };
  }

  factory PSU.fromMap(Map<String, dynamic> map) {
    return PSU(
      id: map['id'],
      modelName: map['model_name'] ?? '',
      brand: map['brand'] ?? '',
      wattage: map['wattage'] ?? 0,
      formFactor: map['form_factor'] ?? '',
      efficiencyRating: map['efficiency_rating'] ?? '',
      price: map['price'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
}

class PSUService {
  static const String tableName = 'PSUtable';
  // Add this function to PSUService class


  // Insert a new PSU WITH SYNC
  static Future<int> insertPSU(PSU psu) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert(tableName, psu.toMap());
    
    //  SYNC WITH PYTHON API AFTER ADDING PSU
    print(' Syncing new PSU with recommendation system...');
    await DatabaseSyncService.syncOnProductAdded('PSU');
    
    final psuWithId = psu.toMap();
    psuWithId['id'] = id;
    await DatabaseSyncService.syncNewComponent(psuWithId, 'psu');
    
    print('PSU added and synced with ID: $id');
    return id;
  }

  static Future<List<PSU>> getAllPSUs() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(tableName);
    return result.map((e) => PSU.fromMap(e)).toList();
  }

  static Future<PSU?> getPSUById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? PSU.fromMap(result.first) : null;
  }

  static Future<int> updatePSU(PSU psu) async {
    final db = await DatabaseService.instance.database;
    final result = await db.update(
      tableName,
      psu.toMap(),
      where: "id = ?",
      whereArgs: [psu.id],
    );
    
    if (result > 0 && psu.id != null) {
      await DatabaseSyncService.syncOnProductUpdated('PSU',psu.id!, psu.toMap());
      
    }
    
    return result;
  }

  static Future<int> deletePSU(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    
    if (result > 0) {
      await DatabaseSyncService.syncOnProductDeletion('PSU', id);
    }
    
    return result;
  }
}