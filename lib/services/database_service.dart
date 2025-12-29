import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();
  final String _userinfoTable = 'userinfo';
  final String _userinfoIdColumnName = 'id';
  final String _userinfoFirstnameColumnName = 'firstname';
  final String _userinfoLastnameColumnName = 'lastname';
  final String _userinfoEmailColumnName ='email';
  final String _userinfoPasswordColumnName = 'password';
  final String _userinfoProfilePicColumnName = 'imageURL';
  DatabaseService._constructor();

  Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    // Ensure the database directory exists
    
    
    final databasePath = join(databaseDirPath, "assemble_db.db");
    
    // Check if database exists and is writable
    
    final database = await openDatabase(
      databasePath,
      version: 1,
      // Enable write-ahead logging for better concurrency
     
      onCreate: (db, version) async {
        // Use batch for better performance
         await db.execute("PRAGMA foreign_keys = ON;");
        Batch batch = db.batch();
        
        // User info table
        batch.execute(''' 
        CREATE TABLE IF NOT EXISTS $_userinfoTable(
        $_userinfoIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_userinfoFirstnameColumnName TEXT NOT NULL,
        $_userinfoLastnameColumnName TEXT NOT NULL,
        $_userinfoEmailColumnName TEXT UNIQUE,
        $_userinfoPasswordColumnName TEXT,
        $_userinfoProfilePicColumnName TEXT
        )
        ''');
        
        batch.execute('''
        CREATE TABLE adminTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstname TEXT NOT NULL,
        lastname TEXT NOT NUll,
        email TEXT UNIQUE,
        password TEXT ,
        type TEXT,
        profilepic TEXT
        )
        ''');
        
        
        batch.execute('''
        CREATE TABLE CPUtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        socket TEXT NOT NULL,
        cores INTEGER NOT NULL,
        threads INTEGER NOT NULL, -- FIXED: Changed TEXT to INTEGER
        baseclock REAL NOT NULL,
        boostclock REAL NOT NULL,
        tdp INTEGER NOT NULL,
        integratedgraphics INTEGER NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // GPU table
        batch.execute('''
        CREATE TABLE GPUtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        vram INTEGER NOT NULL,
        core_clock REAL NOT NULL,
        boostclock REAL NOT NULL,
        tdp INTEGER NOT NULL,
        length_mm INTEGER NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // Motherboard table
        batch.execute('''
        CREATE TABLE motherboardtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        socket TEXT NOT NULL,
        chipset TEXT NOT NULL,
        form_factor TEXT NOT NULL,
        memory_type TEXT NOT NULL,
        memory_slots INTEGER NOT NULL,
        max_memory INTEGER NOT NULL, -- FIXED: Added missing comma
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // RAM table
        batch.execute('''
        CREATE TABLE RAMtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        memory_type TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        speed INTEGER NOT NULL,
        modules INTEGER NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // Storage table
        batch.execute('''
        CREATE TABLE storagetable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        interface TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // PSU table
        batch.execute('''
        CREATE TABLE PSUtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- FIXED: PRIMART -> PRIMARY
        model_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        wattage INTEGER NOT NULL,
        form_factor TEXT NOT NULL, -- FIXED: from_factor -> form_factor
        efficiency_rating TEXT NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // Case table 
        batch.execute('''
        CREATE TABLE casetable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        form_factor TEXT NOT NULL,
        max_gpu_length INTEGER NOT NULL,
        estimated_power INTEGER NOT NULL, -- FIXED: Added missing comma
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // Cooling table
        batch.execute('''
        CREATE TABLE coolingtable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_name TEXT NOT NULL,
        type TEXT NOT NULL,
        supported_sockets TEXT NOT NULL,
        price INTEGER NOT NULL,
        imageURL TEXT NOT NULL
        )
        ''');

        // User build table
        batch.execute('''
CREATE TABLE user_build_table(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  build_name TEXT NOT NULL,
  total_wattage REAL NOT NULL,
  total_price REAL NOT NULL,
  cpu_id INTEGER NOT NULL,
  gpu_id INTEGER,
  motherboard_id INTEGER NOT NULL,
  ram_id INTEGER NOT NULL,
  storage_id INTEGER,
  psu_id INTEGER NOT NULL,
  case_id INTEGER NOT NULL,
  cooler_id INTEGER,
  imageURL TEXT NOT NULL,  
  FOREIGN KEY (user_id) REFERENCES userinfo (id) ON DELETE CASCADE,
  FOREIGN KEY (cpu_id) REFERENCES CPUtable (id),
  FOREIGN KEY (gpu_id) REFERENCES GPUtable (id),
  FOREIGN KEY (motherboard_id) REFERENCES motherboardtable (id),
  FOREIGN KEY (ram_id) REFERENCES RAMtable (id),
  FOREIGN KEY (storage_id) REFERENCES storagetable (id),
  FOREIGN KEY (psu_id) REFERENCES PSUtable (id),
  FOREIGN KEY (case_id) REFERENCES casetable (id),
  FOREIGN KEY (cooler_id) REFERENCES coolingtable (id)
)
''');

        // Execute all table creation statements first
        await batch.commit();

        // Then insert initial admin data after tables are created
        await db.insert('adminTable', {
          'firstname': 'Admin',
          'lastname': 'Admin',
          'email': 'admin@gmail.com',
          'password': 'admin123', 
          'type': 'admin',
          'profilepic': '',
        });

        print('Default admin user created successfully!');
      },
    );
    return database;
  }


  Future<int> insertUser({
   
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? imageURL,
  }) async{
    final db = await database;
    return await db.insert(_userinfoTable, {
  
      _userinfoFirstnameColumnName: firstname,
      _userinfoLastnameColumnName: lastname,
      _userinfoPasswordColumnName: password,
      _userinfoEmailColumnName: email,
      _userinfoProfilePicColumnName: imageURL ?? "",
    });
  }

  Future<Map<String, dynamic>?> loginuser(String email, String password) async{
    final db = await database;
    final result = await db.query(
      _userinfoTable,
      where: '$_userinfoEmailColumnName = ? AND $_userinfoPasswordColumnName = ?',
      whereArgs: [email,password],
    );
    if(result.isNotEmpty){
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      _userinfoTable,
      where: '$_userinfoEmailColumnName = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  
  Future<int> updatePasswordByEmail(String email, String newPassword) async {
    final db = await database;
    return await db.update(
      _userinfoTable,
      {
        _userinfoPasswordColumnName: newPassword,
      },
      where: '$_userinfoEmailColumnName = ?',
      whereArgs: [email],
    );
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      _userinfoTable,
      where: '$_userinfoIdColumnName = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> loginAdmin(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'adminTable',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getAdminById(int id) async {
    final db = await database;
    final result = await db.query(
      'adminTable',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateUser({
    required int id,
    String? firstname,
    String? lastname,
    String? email,
    String? password,
    String? imageURL,
  }) async {
    final db = await database;
    final Map<String, Object?> updates = {};
    if (firstname != null) updates[_userinfoFirstnameColumnName] = firstname;
    if (lastname != null) updates[_userinfoLastnameColumnName] = lastname;
    if (email != null) updates[_userinfoEmailColumnName] = email;
    if (password != null) updates[_userinfoPasswordColumnName] = password;
    if (imageURL != null) updates[_userinfoProfilePicColumnName] = imageURL;

    if (updates.isEmpty) return 0;

    return await db.update(
      _userinfoTable,
      updates,
      where: '$_userinfoIdColumnName = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBuildsByUser(int userId) async {
    
    final db = await database;
    
    return await db.delete(
      
      'user_build_table',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int id) async {
  final db = await database;
  return await db.delete(
    _userinfoTable,
    where: '$_userinfoIdColumnName = ?',
    whereArgs: [id],
  );
}

  Future<int> getTotalBuilds() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM user_build_table');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting total builds: $e');
      return 0;
    }
  }

  Future<int> getTotalUsers() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_userinfoTable');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting total users: $e');
      return 0;
    }
  }
  Future<int> updateAdmin({
    required int id,
    String? firstname,
    String? lastname,
    String? email,
    String? password,
  }) async{

    final db = await database;
    final Map<String, Object> adminupdate ={};
    if(firstname !=null) adminupdate["firstname"] = firstname;
    if(lastname !=null) adminupdate["lastname"] = lastname;
    if(email != null) adminupdate["email"] = email;
    if(password != null) adminupdate["password"] = password;

    if(adminupdate.isEmpty) return 0;

  return await db.update(
  'adminTable',
  adminupdate,
  where: 'id = ?',
  whereArgs: [id]
  );

}
}

