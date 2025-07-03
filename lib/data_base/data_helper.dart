import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../entity/station_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;
  DatabaseHelper._internal();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'station_data.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE station_data (
        commonID TEXT PRIMARY KEY,
        ID TEXT ,
        Gauge TEXT,
        Discharge TEXT,
        TodayRain TEXT,
        DataDate TEXT,
        DataTime TEXT,
        StationID TEXT,
        isSync TEXT
      )
    ''');
  }

  // INSERT
  Future<int> insertStationData(StationData data) async {
    final db = await database;
    return await db.insert(
      'station_data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE
  Future<int> updateStationData(StationData data) async {
    final db = await database;
    return await db.update(
      'station_data',
      data.toMap(),
      where: 'ID = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> updateStationSyncStatus() async {
    final db = await database;
    return await db.update('station_data', {'isSync': "true"});
  }

  // DELETE
  Future<int> deleteStationData(String id) async {
    final db = await database;
    return await db.delete('station_data', where: 'ID = ?', whereArgs: [id]);
  }

  Future<List<StationData>> getAllData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('station_data');
    return List.generate(maps.length, (i) {
      return StationData.fromJson(maps[i]);
    });
  }

  Future<List<StationData>> getUnsyncedData(String isSync) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'station_data',
      where: 'isSync = ?',
      whereArgs: [isSync],
    );
    return List.generate(maps.length, (i) {
      return StationData.fromJson(maps[i]);
    });
  }
}
