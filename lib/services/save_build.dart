import 'package:sqflite/sqflite.dart';

class SaveBuild {
  static Database? _database;

  // Set database instance
  static void setDatabase(Database database) {
    _database = database;
  }

  // Get database instance (you already have this)
  Future<Database> get database async {
    return _database!;
  }

  // ========== USER BUILD TABLE FUNCTIONS ==========

  // CREATE - Save new build
  // CREATE - Save new build
Future<int?> saveUserBuild({
  required int userId,
  required String buildName,
  required double totalWattage,
  required double totalPrice,
  required int cpuId,
  required int motherboardId,
  required int ramId,
  required int psuId,
  required int caseId,
  required String imagePath,  // Added imageURL parameter
  required int gpuId,
   required int  storageId,
  required int  coolerId,
}) async {
  final db = await database;
  try {
    final id = await db.insert(
      'user_build_table',
      {
        'user_id': userId,
        'build_name': buildName,
        'total_wattage': totalWattage,
        'total_price': totalPrice,
        'cpu_id': cpuId,
        'gpu_id': gpuId,
        'motherboard_id': motherboardId,
        'ram_id': ramId,
        'storage_id': storageId,
        'psu_id': psuId,
        'case_id': caseId,
        'cooler_id': coolerId,
        'imageURL': imagePath,  // Added imageURL field
      },
    );
    print('Build saved successfully with ID: $id');
    return id;
  } catch (e) {
    print('Error saving build: $e');
    return null;
  }
}

  // READ - Get builds with ALL component details
 // READ - Get builds with ALL component details
Future<List<Map<String, dynamic>>> getUserBuildsWithDetails(int userId) async {
  final db = await database;
  try {
    final builds = await db.rawQuery('''
      SELECT 
        ub.id as build_id,
        ub.build_name,
        ub.total_wattage,
        ub.total_price,
        ub.imageURL as build_image,  // Added build image URL
        
        -- CPU Details
        cpu.id as cpu_id, cpu.model_name as cpu_name, cpu.price as cpu_price,
        
        -- GPU Details
        gpu.id as gpu_id, gpu.model_name as gpu_name, gpu.price as gpu_price,
        
        -- Motherboard Details
        motherboard.id as motherboard_id, motherboard.model_name as motherboard_name, motherboard.price as motherboard_price,
        
        -- RAM Details
        ram.id as ram_id, ram.model_name as ram_name, ram.price as ram_price,
        
        -- Storage Details
        storage.id as storage_id, storage.model_name as storage_name, storage.price as storage_price,
        
        -- PSU Details
        psu.id as psu_id, psu.model_name as psu_name, psu.price as psu_price,
        
        -- Case Details (including case image URL)
        case.id as case_id, case.model_name as case_name, case.price as case_price, case.imageURL as case_image,
        
        -- Cooler Details
        cooling.id as cooler_id, cooling.model_name as cooler_name, cooling.price as cooler_price
        
      FROM user_build_table ub
      
      LEFT JOIN CPUtable cpu ON ub.cpu_id = cpu.id
      LEFT JOIN GPUtable gpu ON ub.gpu_id = gpu.id
      LEFT JOIN motherboardtable motherboard ON ub.motherboard_id = motherboard.id
      LEFT JOIN RAMtable ram ON ub.ram_id = ram.id
      LEFT JOIN storagetable storage ON ub.storage_id = storage.id
      LEFT JOIN PSUtable psu ON ub.psu_id = psu.id
      LEFT JOIN casetable cs ON ub.case_id = case.id
      LEFT JOIN coolingtable cooling ON ub.cooler_id = cooling.id
      
      WHERE ub.user_id = ?
      ORDER BY ub.id DESC
    ''', [userId]);
    
    return builds;
  } catch (e) {
    print('Error fetching builds with details: $e');
    return [];
  }
}

  // READ - Get single build with ALL details
  Future<Map<String, dynamic>?> getUserBuildByIdWithDetails(int buildId) async {
    final db = await database;
    try {
      final builds = await db.rawQuery('''
        SELECT 
          ub.id as build_id,
          ub.build_name,
          ub.total_wattage,
          ub.total_price,
          
          -- CPU Details
          cpu.id as cpu_id, cpu.model_name as cpu_name, cpu.price as cpu_price,
          
          -- GPU Details
          gpu.id as gpu_id, gpu.model_name as gpu_name, gpu.price as gpu_price,
          
          -- Motherboard Details
          motherboard.id as motherboard_id, motherboard.model_name as motherboard_name, motherboard.price as motherboard_price,
          
          -- RAM Details
          ram.id as ram_id, ram.model_name as ram_name, ram.price as ram_price,
          
          -- Storage Details
          storage.id as storage_id, storage.model_name as storage_name, storage.price as storage_price,
          
          -- PSU Details
          psu.id as psu_id, psu.model_name as psu_name, psu.price as psu_price,
          
          -- Case Details
          cs.id as case_id, cs.model_name as case_name, cs.price as case_price,
          
          -- Cooler Details
          cooling.id as cooler_id, cooling.model_name as cooler_name, cooling.price as cooler_price
          
        FROM user_build_table ub
        
        LEFT JOIN CPUtable cpu ON ub.cpu_id = cpu.id
        LEFT JOIN GPUtable gpu ON ub.gpu_id = gpu.id
        LEFT JOIN motherboardtable motherboard ON ub.motherboard_id = motherboard.id
        LEFT JOIN RAMtable ram ON ub.ram_id = ram.id
        LEFT JOIN storagetable storage ON ub.storage_id = storage.id
        LEFT JOIN PSUtable psu ON ub.psu_id = psu.id
        LEFT JOIN casetable cs ON ub.case_id = cs.id
        LEFT JOIN coolingtable cooling ON ub.cooler_id = cooling.id
        
        WHERE ub.id = ?
      ''', [buildId]);
      
      if (builds.isNotEmpty) {
        return builds.first;
      }
      return null;
    } catch (e) {
      print('Error fetching build with details: $e');
      return null;
    }
  }

  // READ - Get simple builds list (no joins)
  Future<List<Map<String, dynamic>>> getUserBuilds(int userId) async {
    final db = await database;
    try {
      final builds = await db.query(
        'user_build_table',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
      return builds;
    } catch (e) {
      print('Error fetching builds: $e');
      return [];
    }
  }

  // UPDATE
  Future<bool> updateUserBuild({
    required int buildId,
    String? buildName,
    double? totalWattage,
    double? totalPrice,
    int? cpuId,
    int? gpuId,
    int? motherboardId,
    int? ramId,
    int? storageId,
    int? psuId,
    int? caseId,
    int? coolerId,
  }) async {
    final db = await database;
    try {
      final Map<String, dynamic> updateData = {};
      
      if (buildName != null) updateData['build_name'] = buildName;
      if (totalWattage != null) updateData['total_wattage'] = totalWattage;
      if (totalPrice != null) updateData['total_price'] = totalPrice;
      if (cpuId != null) updateData['cpu_id'] = cpuId;
      if (gpuId != null) updateData['gpu_id'] = gpuId;
      if (motherboardId != null) updateData['motherboard_id'] = motherboardId;
      if (ramId != null) updateData['ram_id'] = ramId;
      if (storageId != null) updateData['storage_id'] = storageId;
      if (psuId != null) updateData['psu_id'] = psuId;
      if (caseId != null) updateData['case_id'] = caseId;
      if (coolerId != null) updateData['cooler_id'] = coolerId;
      
      if (updateData.isEmpty) return false;
      
      final count = await db.update(
        'user_build_table',
        updateData,
        where: 'id = ?',
        whereArgs: [buildId],
      );
      
      return count > 0;
    } catch (e) {
      print('Error updating build: $e');
      return false;
    }
  }

  // DELETE
  Future<bool> deleteUserBuild(int buildId) async {
    final db = await database;
    try {
      final count = await db.delete(
        'user_build_table',
        where: 'id = ?',
        whereArgs: [buildId],
      );
      return count > 0;
    } catch (e) {
      print('Error deleting build: $e');
      return false;
    }
  }
}