import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../entity/station_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // Use a static getter for easy access
  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Private method for initializing the database
  static Future<Database> _initDatabase() async {
    // Ensure sqflite plugin is ready
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'station_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE station_data (
            commonID TEXT PRIMARY KEY,
            ID TEXT,
            Gauge TEXT,
            Discharge TEXT,
            TodayRain TEXT,
            DataDate TEXT,
            DataTime TEXT,
            StationID TEXT,
            isSync TEXT
          )
        ''');
      },
    );
  }

  // -------------------
  // CRUD Operations
  // -------------------
  Future<int> insertStationData(StationData data) async {
    final db = await instance;
    return await db.insert(
      'station_data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateStationData(StationData data) async {
    final db = await instance;
    return await db.update(
      'station_data',
      data.toMap(),
      where: 'ID = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> updateStationSyncStatus() async {
    final db = await instance;
    return await db.update('station_data', {'isSync': "true"});
  }

  Future<int> deleteStationData(String id) async {
    final db = await instance;
    return await db.delete('station_data', where: 'ID = ?', whereArgs: [id]);
  }

  Future<List<StationData>> getAllData() async {
    final db = await instance;
    final List<Map<String, dynamic>> maps = await db.query('station_data');
    return List.generate(maps.length, (i) => StationData.fromJson(maps[i]));
  }

  Future<List<StationData>> getUnsyncedData(String isSync) async {
    final db = await instance;
    final List<Map<String, dynamic>> maps = await db.query(
      'station_data',
      where: 'isSync = ?',
      whereArgs: [isSync],
    );
    return List.generate(maps.length, (i) => StationData.fromJson(maps[i]));
  }
}
